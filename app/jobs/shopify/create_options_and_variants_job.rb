# frozen_string_literal: true

module Shopify
  class CreateOptionsAndVariantsJob < Shopify::ApiJob
    def perform(product_id, shopify_product_id)
      Product::Shopify::OptionsPush.call(product_id:, product_store_id: shopify_product_id)
    end
  end
end
