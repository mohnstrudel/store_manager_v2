# frozen_string_literal: true

module Shopify
  class PullVariantsJob < ApplicationJob
    def perform(product, parsed_variants)
      parsed_variants.each do |parsed_variant|
        Variant::Shopify::Importer.import!(product, parsed_variant)
      rescue => error
        raise StandardError, format_import_error(error, product:, parsed_variant:)
      end
    end

    private

    def format_import_error(error, product:, parsed_variant:)
      [
        error.message,
        "product_id: #{product.id}",
        "product_shopify_id: #{product.shopify_info&.store_id || product.shopify_id || "blank"}",
        "variant_store_id: #{parsed_variant[:store_id].presence || "blank"}",
        "variant_sku: #{parsed_variant[:sku].presence || "blank"}"
      ].join("\n")
    end
  end
end
