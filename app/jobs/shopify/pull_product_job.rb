# frozen_string_literal: true

module Shopify
  class PullProductJob < ApplicationJob
    queue_as :default

    def perform(shopify_product_id)
      api_client = Shopify::ApiClient.new
      response = api_client.pull_product(shopify_product_id)

      if response.blank?
        handle_product_not_found(shopify_product_id)
        return
      end

      parsed_product = Shopify::ProductParser
        .new(api_item: response)
        .parse

      Shopify::ProductCreator.new(parsed_item: parsed_product).update_or_create!
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
