# frozen_string_literal: true

module Shopify
  class UpdateProductJob < ApplicationJob
    def perform(product_id)
      api_client = Shopify::ApiClient.new
      product = Product.find(product_id)
      product_shopify_info = product.shopify_info

      serialized_product = Shopify::ProductSerializer.serialize(product)

      product_response = api_client.product_update(product_shopify_info.store_id, serialized_product)

      product_shopify_info.assign_attributes(
        push_time: Time.current,
        slug: product_response["handle"]
      )
      product_shopify_info.save!

      remove_outdated_media(product, product_response)

      if product.media.any?
        Shopify::PushMediaJob.perform_later(product_shopify_info.store_id, product.id)
      end

      if product.sizes.any? || product.versions.any? || product.colors.any?
        Shopify::CreateOptionsAndVariantsJob.perform_later(product.id, product_shopify_info.store_id)
      end

      true
    rescue ShopifyApiError => e
      if e.message.include?("Product does not exist")
        handle_product_not_found_error(product)
      else
        raise
      end
    end

    private

    def remove_outdated_media(product, product_response)
      shopify_media_ids = product_response.dig("media", "nodes")&.pluck("id") || []

      StoreInfo
        .where(
          storable_type: "Media",
          storable_id: product.media.select(:id),
          store_name: "shopify"
        )
        .where.not(store_id: shopify_media_ids)
        .delete_all
    end

    def handle_product_not_found_error(product)
      shopify_info = product.shopify_info
      return unless shopify_info

      StoreInfo
        .where(
          store_name: "shopify",
          storable_type: "Media",
          storable_id: product.media.select(:id)
        )
        .delete_all

      shopify_info.destroy!
    end
  end
end
