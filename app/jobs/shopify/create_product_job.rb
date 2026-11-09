# frozen_string_literal: true

module Shopify
  class CreateProductJob < ApplicationJob
    def perform(product_id)
      Product.find(product_id).create_in_shopify_now
    end
  end
end
