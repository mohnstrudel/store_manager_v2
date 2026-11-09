# frozen_string_literal: true

module Shopify
  class PushMediaJob < Shopify::ApiJob
    def perform(product_id, product_store_id)
      Product::Shopify::Media::Push.call(product_id:, product_store_id:)
    end
  end
end
