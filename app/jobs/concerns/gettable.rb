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
      step.times {
        progressbar.increment
        sleep 0.25
      }
      while page <= pages
        response = HTTParty.get(
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
        result.concat(JSON.parse(response.body, symbolize_names: true))
        step.times {
          progressbar.increment
          sleep 0.25
        }
        page += 1
      end
      result
    end

    def api_get(url, status = nil)
      response = HTTParty.get(
        url,
        query: {
          status:
        }.compact,
        basic_auth: {
          username: CONSUMER_KEY,
          password: CONSUMER_SECRET
        }
      )
      JSON.parse(response.body, symbolize_names: true)
    end
  end
end
