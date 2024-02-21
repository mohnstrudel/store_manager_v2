module Gettable
  extend ActiveSupport::Concern

  CONSUMER_KEY = Rails.application.credentials.dig(:woo_api, :user)
  CONSUMER_SECRET = Rails.application.credentials.dig(:woo_api, :pass)

  included do
    def api_get_all(url, total, status = nil)
      per_page = 100
      progressbar = ProgressBar.create(title: self.class.name)
      step = (total < per_page) ? 1 : (100 / (total / per_page))
      pages = (total < per_page) ? 1 : (total / per_page).ceil
      page = 1
      result = []
      while page <= pages
        step.times {
          progressbar.increment
          sleep 0.25
        }
        retries = 0
        response = begin
          HTTParty.get(
            url,
            query: {
              status:,
              page:,
              per_page:
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
        result.concat(JSON.parse(response.body, symbolize_names: true))
        page += 1
      end
      result.compact_blank
    end

    def api_get(url, status = nil)
      retries = 0
      response = begin
        HTTParty.get(
          url,
          query: {
            status:
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
