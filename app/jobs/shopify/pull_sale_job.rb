# frozen_string_literal: true

module Shopify
  class PullSaleJob < ApplicationJob
    queue_as :default

    def perform(sale_id)
      raise ArgumentError, "Shopify order ID is required" if sale_id.blank?

      client = Shopify::Api::Client.new
      response = client.pull_order(sale_id)

      parsed = Sale::ShopifyParser.parse(response)
      Sale::ShopifyImporter.import!(parsed)
    end
  end
end
