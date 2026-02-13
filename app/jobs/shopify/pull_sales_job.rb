# frozen_string_literal: true

module Shopify
  class PullSalesJob < Shopify::BasePullJob
    private

    def fetch_from_api(api_client, cursor:, batch_size:)
      api_client.fetch_orders(cursor: cursor, batch_size: batch_size)
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
