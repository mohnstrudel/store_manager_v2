module Gettable
  extend ActiveSupport::Concern

  CONSUMER_KEY = Rails.application.credentials.dig(:woo_api, :user)
  CONSUMER_SECRET = Rails.application.credentials.dig(:woo_api, :pass)
  PER_PAGE = 100

  included do
    def api_get_all(url, total, status = nil, page = 1)
      total = total.to_i
      pages = (total < PER_PAGE) ? 1 : (total / PER_PAGE).ceil

      progressbar = ProgressBar.create(title: self.class.name)
      progress_step = 100 / pages

      if page < 0
        page = pages + page
        progress_step = (100 / (pages - page)).floor
      end

      result = []

      while page <= pages
        unless progressbar.finished?
          progress_step.times {
            progressbar.increment
            sleep 0.25
          }
        end
        parsed_payload = api_get(url, status, PER_PAGE, page)
        result.concat(parsed_payload)
        page += 1
      end

      result.compact_blank
    end

    def api_get_latest(url)
      api_get(url, nil, PER_PAGE, 1, "asc")
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
