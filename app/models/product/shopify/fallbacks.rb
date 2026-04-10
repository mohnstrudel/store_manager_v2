# frozen_string_literal: true

require "digest"

module Product::Shopify::Fallbacks
  extend ActiveSupport::Concern

  FALLBACK_FRANCHISE_TITLE = "Broken Shopify Products"
  FALLBACK_SHAPE_TITLE = "Unknown Shopify Shape"
  TITLE_PREFIX = "[BROKEN SHOPIFY PRODUCT]"
  SKU_PREFIX = "broken-shopify"

  class_methods do
    def find_or_create_shopify_placeholder!(store_id:)
      find_by_shopify_id(store_id) || create_shopify_placeholder!(store_id:)
    end

    private

    def create_shopify_placeholder!(store_id:)
      create!(
        title: "#{TITLE_PREFIX} #{short_store_id(store_id)}",
        franchise: Franchise.find_or_create_by!(title: FALLBACK_FRANCHISE_TITLE),
        shape: Shape.find_or_create_by!(title: FALLBACK_SHAPE_TITLE),
        sku: deterministic_shopify_placeholder_sku(store_id),
        full_title: "#{FALLBACK_FRANCHISE_TITLE} -- #{TITLE_PREFIX} #{short_store_id(store_id)}"
      ).tap do |product|
        product.store_infos.create!(
          store_name: :shopify,
          store_id: store_id,
          pull_time: Time.zone.now
        )
      end
    end

    def deterministic_shopify_placeholder_sku(store_id)
      "#{SKU_PREFIX}-#{Digest::SHA256.hexdigest(store_id).first(12)}"
    end

    def short_store_id(store_id)
      store_id.split("/").last
    end
  end
end
