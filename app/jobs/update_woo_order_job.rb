# frozen_string_literal: true
class UpdateWooOrderJob < ApplicationJob
  queue_as :default

  URL = "https://store.handsomecake.com/wp-json/wc/v3/orders/"
  CONSUMER_KEY = Rails.application.credentials.dig(:woo_api_write, :user)
  CONSUMER_SECRET = Rails.application.credentials.dig(:woo_api_write, :pass)

  def perform(sale)
    update_order(sale)
  end

  def update_order(sale)
    order_url = URL + sale[:woo_id]
    HTTParty.post(
      order_url,
      body: {
        status: sale[:status]
      },
      basic_auth: {
        username: CONSUMER_KEY,
        password: CONSUMER_SECRET
      }
    )
  end
end
