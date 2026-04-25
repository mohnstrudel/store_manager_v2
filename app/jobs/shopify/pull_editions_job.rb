# frozen_string_literal: true

module Shopify
  class PullEditionsJob < ApplicationJob
    def perform(product, parsed_editions)
      parsed_editions.each do |parsed_edition|
        Edition::Shopify::Importer.import!(product, parsed_edition)
      rescue StandardError => error
        raise StandardError, format_import_error(error, product:, parsed_edition:)
      end
    end

    private

    def format_import_error(error, product:, parsed_edition:)
      [
        error.message,
        "product_id: #{product.id}",
        "product_shopify_id: #{product.shopify_info&.store_id || product.shopify_id || "blank"}",
        "edition_store_id: #{parsed_edition[:store_id].presence || "blank"}",
        "edition_sku: #{parsed_edition[:sku].presence || "blank"}"
      ].join("\n")
    end
  end
end
