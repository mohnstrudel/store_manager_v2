# frozen_string_literal: true

module Shopify
  class UpdateProductJob < ApplicationJob
    def perform(product_id)
      Product.find(product_id).update_in_shopify_now
    end
  end
end
