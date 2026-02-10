# frozen_string_literal: true

module Shopify
  class PullSalesJob < Shopify::BasePullJob
    private

    def resource_name
      "orders"
    end

    def parser_class
      Sale::ShopifyParser
    end

    def creator_class
      Sale::ShopifyImporter
    end

    def batch_size
      250
    end
  end
end
