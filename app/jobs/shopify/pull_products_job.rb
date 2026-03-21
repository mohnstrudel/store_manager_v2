# frozen_string_literal: true

module Shopify
  class PullProductsJob < Shopify::BasePullJob
    private

    def fetch_from_api(api_client, cursor:, batch_size:)
      api_client.fetch_products(cursor: cursor, batch_size: batch_size)
    end

    def parser_class
      Product::Shopify::Parser
    end

    def creator_class
      Product::Shopify::Importer
    end

    def batch_size
      250
    end
  end
end
