module Gettable
  extend ActiveSupport::Concern

  CONSUMER_KEY = Rails.application.credentials.dig(:woo_api, :user)
  CONSUMER_SECRET = Rails.application.credentials.dig(:woo_api, :pass)
  PER_PAGE = 100

  included do
    def api_get_all(url, total_records, pages = nil, status = nil)
      total_records = total_records.to_i
      pages ||= (total_records < PER_PAGE) ? 1 : (total_records / PER_PAGE).ceil

      result = []

      (1..pages).each do |page|
        parsed_payload = api_get(url, status, PER_PAGE, page)
        result << parsed_payload
      end

      result.flatten.compact_blank
    end

    def api_get_latest_orders
      orders_api_endpoint = "https://store.handsomecake.com/wp-json/wc/v3/orders/"
      api_get(orders_api_endpoint, nil, PER_PAGE, 1)
    end

    def api_get(url, status = nil, per_page = nil, page = nil, order = nil)
      retries = 0
      response = begin
        HTTParty.get(
          url,
          query: {
            status:,
            per_page:,
            page:,
            order:
          }.compact,
          basic_auth: {
            username: CONSUMER_KEY,
            password: CONSUMER_SECRET
          }
        )
      rescue => e
        retries += 1
        if retries < 3
          sleep 10
          retry
        else
          Rails.logger.error "Gettable. Error: #{e.message}"
          nil
        end
      end
      JSON.parse(response.body, symbolize_names: true)
    end
  end
end
