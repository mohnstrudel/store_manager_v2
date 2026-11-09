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

        (1..pages)
          .map { |page| get(url, status:, per_page: PER_PAGE, page:, orderby:) }
          .flatten
          .compact_blank
      end

      def get(url, status: nil, per_page: nil, page: nil, orderby: nil)
        query = {status:, per_page:, page:, orderby:}.compact

        response = perform_get_request(url, query)
        return if response.blank?

        parse_get_response(response, url:, query:)
      end

      def perform_get_request(url, query)
        retries = 0

        begin
          HTTParty.get(
            url,
            query:,
            basic_auth: {
              username: CONSUMER_KEY,
              password: CONSUMER_SECRET
            }
          )
        rescue => e
          retries += 1
          retry if retries < 3 && retry_get_request?

          report_get_request_failure(url:, query:, error: e, retries:)
          nil
        end
      end

      def retry_get_request?
        sleep 10
        true
      end

      def report_get_request_failure(url:, query:, error:, retries:)
        Rails.logger.error "Gettable. Error: #{error.class}: #{error.message}"
        Sentry.capture_message(
          "Woo API GET failed after retries",
          level: :error,
          tags: sentry_tags,
          extra: {
            url:,
            query:,
            error_class: error.class.name,
            error_message: error.message,
            retries:
          }
        )
      end

      def sentry_tags
        {
          integration: "woo",
          concern: "Gettable"
        }
      end

      def parse_get_response(response, url:, query:)
        unless response_successful?(response)
          report_unsuccessful_get_response(
            url:,
            query:,
            response:,
            error_payload: parse_error_payload(response.body)
          )
          return nil
        end

        if response.body.blank?
          report_blank_get_response(url:, query:, response:)
          return nil
        end

        JSON.parse(response.body, symbolize_names: true)
      rescue JSON::ParserError => e
        report_invalid_get_response(url:, query:, response:, error: e)
        nil
      end

      def response_successful?(response)
        return response.success? if response.respond_to?(:success?)

        response.code.to_i.between?(200, 299)
      end

      def report_unsuccessful_get_response(url:, query:, response:, error_payload:)
        Rails.logger.error("Gettable. Unsuccessful response for #{url}: HTTP #{response.code}")
        Sentry.capture_message(
          "Woo API GET returned unsuccessful response",
          level: :error,
          tags: sentry_tags,
          extra: {
            url:,
            query:,
            status_code: response.code.to_i,
            error_code: error_payload&.dig(:code),
            error_message: error_payload&.dig(:message),
            error_data: error_payload&.dig(:data),
            body_preview: response.body.to_s.first(500)
          }
        )
      end

      def parse_error_payload(body)
        return if body.blank?

        JSON.parse(body, symbolize_names: true)
      rescue JSON::ParserError
        nil
      end

      def report_blank_get_response(url:, query:, response:)
        Rails.logger.warn("Gettable. Blank response body for #{url}")
        Sentry.capture_message(
          "Woo API GET returned blank body",
          level: :warning,
          tags: sentry_tags,
          extra: {
            url:,
            query:,
            response_class: response.class.name
          }
        )
      end

      def report_invalid_get_response(url:, query:, response:, error:)
        Rails.logger.error "Gettable. Failed to parse response for #{url}: #{error.message}"
        Sentry.capture_message(
          "Woo API GET returned invalid JSON",
          level: :error,
          tags: sentry_tags,
          extra: {
            url:,
            query:,
            error_message: error.message,
            body_preview: response.body.to_s.first(500)
          }
        )
      end
    end
  end
end
