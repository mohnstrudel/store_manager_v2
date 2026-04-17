# frozen_string_literal: true

module Gettable
  extend ActiveSupport::Concern

  CONSUMER_KEY = Rails.application.credentials.dig(:woo_api, :user) || ENV.fetch("WOO_API_USER", "")
  CONSUMER_SECRET = Rails.application.credentials.dig(:woo_api, :pass) || ENV.fetch("WOO_API_PASS", "")
  PER_PAGE = 100

  included do
    def api_get_all(url, total_records, pages = nil, status = nil)
      total_records = total_records.to_i
      pages ||= (total_records <= PER_PAGE) ? 1 : total_records.fdiv(PER_PAGE).ceil

      result = []

      (1..pages).each do |page|
        parsed_payload = api_get(url, status, PER_PAGE, page)
        result << parsed_payload
      end

      result.flatten.compact_blank
    end

    def api_get_order(id)
      api_get("https://store.handsomecake.com/wp-json/wc/v3/orders/#{id}")
    end

    def api_get_latest_orders
      orders_api_endpoint = "https://store.handsomecake.com/wp-json/wc/v3/orders/"
      api_get(orders_api_endpoint, nil, PER_PAGE, 1)
    end

    def api_get(url, status = nil, per_page = nil, page = nil, order = nil)
      query = {status:, per_page:, page:, order:}.compact

      response = perform_api_get_request(url, query)
      return if response.blank?

      parse_api_get_response(response, url:, query:)
    end

    private

    def perform_api_get_request(url, query)
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
        retry if retries < 3 && retry_api_get_request?

        report_api_get_request_failure(url:, query:, error: e, retries:)
        nil
      end
    end

    def retry_api_get_request?
      sleep 10
      true
    end

    def parse_api_get_response(response, url:, query:)
      unless api_get_response_successful?(response)
        report_unsuccessful_api_get_response(
          url:,
          query:,
          response:,
          error_payload: parse_api_get_error_payload(response.body)
        )
        return nil
      end

      if response.body.blank?
        report_blank_api_get_response(url:, query:, response:)
        return nil
      end

      JSON.parse(response.body, symbolize_names: true)
    rescue JSON::ParserError => e
      report_invalid_api_get_response(url:, query:, response:, error: e)
      nil
    end

    def api_get_response_successful?(response)
      return response.success? if response.respond_to?(:success?)

      response.code.to_i.between?(200, 299)
    end

    def report_api_get_request_failure(url:, query:, error:, retries:)
      Rails.logger.error "Gettable. Error: #{error.class}: #{error.message}"
      Sentry.capture_message(
        "Woo API GET failed after retries",
        level: :error,
        tags: woo_api_get_tags,
        extra: {
          url:,
          query:,
          error_class: error.class.name,
          error_message: error.message,
          retries:
        }
      )
    end

    def report_unsuccessful_api_get_response(url:, query:, response:, error_payload:)
      Rails.logger.error("Gettable. Unsuccessful response for #{url}: HTTP #{response.code}")
      Sentry.capture_message(
        "Woo API GET returned unsuccessful response",
        level: :error,
        tags: woo_api_get_tags,
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

    def report_blank_api_get_response(url:, query:, response:)
      Rails.logger.warn("Gettable. Blank response body for #{url}")
      Sentry.capture_message(
        "Woo API GET returned blank body",
        level: :warning,
        tags: woo_api_get_tags,
        extra: {
          url:,
          query:,
          response_class: response.class.name
        }
      )
    end

    def report_invalid_api_get_response(url:, query:, response:, error:)
      Rails.logger.error "Gettable. Failed to parse response for #{url}: #{error.message}"
      Sentry.capture_message(
        "Woo API GET returned invalid JSON",
        level: :error,
        tags: woo_api_get_tags,
        extra: {
          url:,
          query:,
          error_message: error.message,
          body_preview: response.body.to_s.first(500)
        }
      )
    end

    def parse_api_get_error_payload(body)
      return if body.blank?

      JSON.parse(body, symbolize_names: true)
    rescue JSON::ParserError
      nil
    end

    def woo_api_get_tags
      {
        integration: "woo",
        concern: "Gettable"
      }
    end
  end
end
