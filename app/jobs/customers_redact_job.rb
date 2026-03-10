# frozen_string_literal: true

class CustomersRedactJob < ApplicationJob
  extend ShopifyAPI::Webhooks::WebhookHandler

  class << self
    def handle(data:)
      perform_later(topic: data.topic, shop_domain: data.shop, webhook: data.body)
    end
  end

  def perform(topic:, shop_domain:, webhook:)
    shop = Shop.find_by(shopify_domain: shop_domain)

    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")

      raise ActiveRecord::RecordNotFound, "Shop Not Found"
    end

    shop.with_shopify_session do
    end
  end
end
