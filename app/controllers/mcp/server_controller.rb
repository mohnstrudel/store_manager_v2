# frozen_string_literal: true

module Mcp
  class ServerController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :require_authentication
    skip_before_action :set_sentry_user
    skip_before_action :authorize_resourse
    skip_after_action :verify_authorized

    PROTOCOL_VERSION = "2024-11-05"

    def handle
      body = JSON.parse(request.body.read, symbolize_names: true)

      if body.is_a?(Array)
        responses = body.filter_map { route(it) }
        responses.any? ? render(json: responses) : head(:no_content)
      else
        result = route(body)
        result ? render(json: result) : head(:no_content)
      end
    rescue JSON::ParserError
      render json: error_envelope(nil, -32700, "Parse error"), status: :bad_request
    end

    private

    def route(req)
      id = req[:id]

      # JSON-RPC notifications — "if id.nil?" — must not receive a response
      return nil if id.nil?

      case req[:method]
      when "initialize" then initialize_response(id)
      when "tools/list" then tools_list_response(id)
      when "tools/call" then tool_call_response(id, req[:params] || {})
      else error_envelope(id, -32601, "Method not found: #{req[:method]}")
      end
    end

    def initialize_response(id)
      {
        jsonrpc: "2.0",
        id:,
        result: {
          protocolVersion: PROTOCOL_VERSION,
          capabilities: {tools: {}},
          serverInfo: {name: "store-manager", version: "1.0"}
        }
      }
    end

    def tools_list_response(id)
      {
        jsonrpc: "2.0",
        id:,
        result: {
          tools: [
            {
              name: "get_sale_status",
              description: "Get the tracking status and description for items in a sale order",
              inputSchema: {
                type: "object",
                properties: {
                  orderIdentifier: {
                    type: "string",
                    description: "Order ID (Shopify name, e.g. HSCM#1001, or WooCommerce order ID)"
                  }
                },
                required: ["orderIdentifier"]
              }
            }
          ]
        }
      }
    end

    def tool_call_response(id, params)
      tool_name = params[:name]

      unless tool_name == "get_sale_status"
        return error_envelope(id, -32602, "Unknown tool: #{tool_name}")
      end

      arguments = params[:arguments] || {}
      order_id = arguments[:orderIdentifier] || arguments["orderIdentifier"]

      if order_id.blank?
        return tool_error(id, "Order identifier is required")
      end

      sale = Sale.find_recent_by_order_id(order_id)

      unless sale
        return tool_error(id, "Order '#{order_id}' not found")
      end

      tool_success(id, sale.item_tracking_payload)
    end

    def tool_success(id, data)
      {jsonrpc: "2.0", id:, result: {content: [{type: "text", text: data.to_json}], isError: false}}
    end

    def tool_error(id, message)
      {jsonrpc: "2.0", id:, result: {content: [{type: "text", text: message}], isError: true}}
    end

    def error_envelope(id, code, message)
      {jsonrpc: "2.0", id:, error: {code:, message:}}
    end
  end
end
