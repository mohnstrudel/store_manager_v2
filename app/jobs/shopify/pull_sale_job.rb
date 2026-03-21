# frozen_string_literal: true

module Shopify
  class PullSaleJob < ApplicationJob
    def perform(sale_store_id)
      raise ArgumentError, "Sale store_id is required" if sale_store_id.blank?

      client = Shopify::Api::Client.new
      response = client.fetch_order(sale_store_id)

      parsed = Sale::Shopify::Parser.parse(response)
      Sale::Shopify::Importer.import!(parsed)
    end
  end
end
