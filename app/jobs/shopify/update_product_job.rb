# frozen_string_literal: true

module Shopify
  class UpdateProductJob < ApplicationJob
    def perform(product_id)
      client = Shopify::Api::Client.new
      product = Product.find(product_id)
      shopify_info = product.shopify_info

      serialized_product = Product::Shopify::Payload.for_export(product)
      product_payload = client.update_product(shopify_info.store_id, serialized_product)

      shopify_info.assign_attributes(
        push_time: Time.current,
        slug: product_payload["handle"]
      )
      shopify_info.save!

      remove_outdated_media(product, product_payload)

      if product.media.any?
        Shopify::PushMediaJob.perform_later(product.id, shopify_info.store_id)
      end

      if product.sizes.any? || product.versions.any? || product.colors.any?
        Shopify::CreateOptionsAndVariantsJob.perform_later(product.id, shopify_info.store_id)
      end

      true
    rescue Shopify::Api::Client::ApiError => e
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
