# frozen_string_literal: true

module Shopify
  class PullProductJob < ApplicationJob
    queue_as :default

    def perform(shopify_product_id)
      payload = Shopify::Api::Client.new.fetch_product(shopify_product_id)

      if payload.blank?
        Product.forget_shopify_listing(shopify_product_id)
      else
        Product::Shopify::Importer.import(Product::Shopify::Parser.parse(payload))
      end
    end
  end
end
