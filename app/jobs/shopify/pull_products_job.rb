# frozen_string_literal: true

module Shopify
  class PullProductsJob < Shopify::BasePullJob
    private

    def resource_name
      "products"
    end

    def parser_class
      Product::ShopifyParser
    end

    def creator_class
      Product::ShopifyImporter
    end

    def batch_size
      250
    end
  end
end
