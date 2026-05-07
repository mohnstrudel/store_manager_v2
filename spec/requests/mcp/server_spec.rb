# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mcp::ServerController do
  let(:json_headers) { {"CONTENT_TYPE" => "application/json"} }

  def post_mcp(body)
    post "/mcp", params: body.to_json, headers: json_headers
  end

  def parsed_response
    JSON.parse(response.body, symbolize_names: true)
  end

  describe "POST /mcp" do
    context "with method: initialize" do
      before { post_mcp({jsonrpc: "2.0", id: 1, method: "initialize", params: {protocolVersion: "2024-11-05", capabilities: {}}}) }

      it { expect(response).to have_http_status(:ok) }

      it "returns the protocol version and server info" do
        result = parsed_response[:result]

        aggregate_failures do
          expect(result[:protocolVersion]).to eq("2024-11-05")
          expect(result[:serverInfo][:name]).to eq("store-manager")
          expect(result[:capabilities]).to include(:tools)
        end
      end
    end

    context "with method: tools/list" do
      before { post_mcp({jsonrpc: "2.0", id: 2, method: "tools/list"}) }

      it "returns the get_sale_status tool" do
        tools = parsed_response[:result][:tools]

        aggregate_failures do
          expect(tools.length).to eq(1)
          expect(tools.first[:name]).to eq("get_sale_status")
          expect(tools.first[:inputSchema][:required]).to include("orderIdentifier")
        end
      end
    end

    context "with method: tools/call — get_sale_status" do
      let(:warehouse) { create(:warehouse, external_name_de: "Im Zulauf", desc_de: "Ware unterwegs") }
      let(:sale) { create(:sale, shopify_name: "HSCM#9001") }

      before do
        sale_item = create(:sale_item, sale:)
        create(:purchase_item, warehouse:, sale_item:)

        post_mcp({
          jsonrpc: "2.0",
          id: 3,
          method: "tools/call",
          params: {name: "get_sale_status", arguments: {orderIdentifier: "HSCM#9001"}}
        })
      end

      it { expect(response).to have_http_status(:ok) }

      it "returns tracking status in a text content block" do
        result = parsed_response[:result]
        content = result[:content].first

        aggregate_failures do
          expect(result[:isError]).to be false
          expect(content[:type]).to eq("text")
          data = JSON.parse(content[:text], symbolize_names: true)
          expect(data.first[:status]).to eq("Im Zulauf")
          expect(data.first[:description]).to eq("Ware unterwegs")
        end
      end
    end

    context "with method: tools/call — order not found" do
      before do
        post_mcp({
          jsonrpc: "2.0",
          id: 4,
          method: "tools/call",
          params: {name: "get_sale_status", arguments: {orderIdentifier: "HSCM#0000"}}
        })
      end

      it "returns a tool-level error with isError: true" do
        result = parsed_response[:result]

        aggregate_failures do
          expect(result[:isError]).to be true
          expect(result[:content].first[:text]).to include("not found")
        end
      end
    end

    context "with method: tools/call — missing orderIdentifier" do
      before do
        post_mcp({
          jsonrpc: "2.0",
          id: 5,
          method: "tools/call",
          params: {name: "get_sale_status", arguments: {}}
        })
      end

      it "returns a tool-level error" do
        expect(parsed_response[:result][:isError]).to be true
      end
    end

    context "with an unknown method" do
      before { post_mcp({jsonrpc: "2.0", id: 6, method: "unknown/method"}) }

      it "returns a JSON-RPC method-not-found error" do
        expect(parsed_response[:error][:code]).to eq(-32601)
      end
    end

    context "with a notification (no id)" do
      before { post_mcp({jsonrpc: "2.0", method: "notifications/initialized"}) }

      it { expect(response).to have_http_status(:no_content) }
    end

    context "with invalid JSON" do
      before do
        post "/mcp", params: "not-json{{{", headers: json_headers
      end

      it "returns a parse error" do
        expect(parsed_response[:error][:code]).to eq(-32700)
      end
    end

    context "with a batch of requests" do
      before do
        post_mcp([
          {jsonrpc: "2.0", id: 7, method: "initialize", params: {protocolVersion: "2024-11-05", capabilities: {}}},
          {jsonrpc: "2.0", id: 8, method: "tools/list"}
        ])
      end

      it "returns an array with one response per non-notification request" do
        expect(parsed_response.length).to eq(2)
      end
    end
  end
end
