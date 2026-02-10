# frozen_string_literal: true

module Shopify
  class PullProductJob < ApplicationJob
    queue_as :default

    def perform(shopify_product_id)
      client = Shopify::Api::Client.new
      payload = client.fetch_product(shopify_product_id)

      if payload.blank?
        handle_product_not_found(shopify_product_id)
        return
      end

      parsed_payload = Product::ShopifyParser.parse(payload)
      Product::ShopifyImporter.import!(parsed_payload)
    end

    private

    def handle_product_not_found(shopify_product_id)
      store_info = StoreInfo.find_by(store_name: "shopify", store_id: shopify_product_id)

      return unless store_info

      StoreInfo
        .where(
          store_name: "shopify",
          storable_type: "Media",
          storable_id: store_info.storable.media.select(:id)
        )
        .delete_all

      store_info.destroy!
    end
  end
end
