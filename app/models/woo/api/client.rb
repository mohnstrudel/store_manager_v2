# frozen_string_literal: true

module Woo
  module Api
    class Client
      CONSUMER_KEY = ENV.fetch("WOO_API_USER", "")
      CONSUMER_SECRET = ENV.fetch("WOO_API_PASS", "")
      PER_PAGE = 100
      ORDERS_URL = "https://store.handsomecake.com/wp-json/wc/v3/orders/"
      PRODUCTS_URL = "https://store.handsomecake.com/wp-json/wc/v3/products/"
      ORDERS_ORDER_BY = "modified"
      PUBLISHED_STATUS = "publish"
      NETWORK_ERRORS = [
        Timeout::Error,
        SocketError,
        SystemCallError,
        IOError,
        OpenSSL::SSL::SSLError,
        Net::ProtocolError,
        Net::HTTPBadResponse,
        HTTParty::Error
      ].freeze
      BODY_PREVIEW_LENGTH = 500

      class Error < StandardError
        attr_reader :status, :url, :body_preview

        def initialize(message, status: nil, url: nil, body_preview: nil)
          super(message)
          @status = status
          @url = url
          @body_preview = body_preview
        end
      end

      class Unavailable < Error; end

      class NotFound < Error; end

      def fetch_orders(total_records, pages = nil)
        fetch_all(ORDERS_URL, total_records, pages, orderby: ORDERS_ORDER_BY)
      end

      def fetch_order(id)
        get("#{ORDERS_URL}#{id}")
      end

      def fetch_latest_orders
        get(ORDERS_URL, per_page: PER_PAGE, page: 1, orderby: ORDERS_ORDER_BY)
      end

      def fetch_product(woo_id)
        get("#{PRODUCTS_URL}#{woo_id}", status: PUBLISHED_STATUS)
      end

      def update_order_status(order_id, status)
        HTTParty.post(
          "#{ORDERS_URL}#{order_id}",
          body: {status:},
          basic_auth: {
            username: CONSUMER_KEY,
            password: CONSUMER_SECRET
          }
        )
      end

      private

      def fetch_all(url, total_records, pages, status: nil, orderby: nil)
        total_records = total_records.to_i
        pages ||= (total_records <= PER_PAGE) ? 1 : total_records.fdiv(PER_PAGE).ceil

        (1..pages).flat_map { |page| get(url, status:, per_page: PER_PAGE, page:, orderby:) }
      end

      def get(url, status: nil, per_page: nil, page: nil, orderby: nil)
        query = {status:, per_page:, page:, orderby:}.compact

        response = perform_get_request(url, query)
        parse_body(response, url:)
      end

      def perform_get_request(url, query)
        HTTParty.get(
          url,
          query:,
          basic_auth: {
            username: CONSUMER_KEY,
            password: CONSUMER_SECRET
          }
        )
      rescue *NETWORK_ERRORS => error
        raise Unavailable.new("Woo API GET #{url} failed: #{error.class}: #{error.message}", url:)
      end

      def parse_body(response, url:)
        raise_rejection(response, url:) unless response.code.to_i.between?(200, 299)
        raise_rejection(response, url:, reason: "blank body") if response.body.blank?

        JSON.parse(response.body, symbolize_names: true)
      rescue JSON::ParserError
        raise_rejection(response, url:, reason: "invalid JSON")
      end

      def raise_rejection(response, url:, reason: nil)
        status = response.code.to_i
        body = response.body.to_s
        error_class = error_class_for(status)
        detail = reason || error_message(body) || "unexpected response"

        raise error_class.new(
          "Woo API GET #{url} returned HTTP #{status}: #{detail}",
          status:,
          url:,
          body_preview: body.first(BODY_PREVIEW_LENGTH)
        )
      end

      def error_class_for(status)
        if status == 404
          NotFound
        elsif status == 429 || status >= 500
          Unavailable
        else
          Error
        end
      end

      def error_message(body)
        return if body.blank?

        JSON.parse(body, symbolize_names: true).then { |payload| payload[:message] if payload.is_a?(Hash) }
      rescue JSON::ParserError
        nil
      end
    end
  end
end
