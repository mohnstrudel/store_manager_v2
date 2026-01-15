# frozen_string_literal: true

module Shopify
  class PushMediaJob < ApplicationJob
    def perform(shopify_product_id, product_id)
      product = Product.find(product_id)
      return unless product&.media&.any?

      unsynced_media = product.media.reject do |m|
        m.store_infos.exists?(store_name: :shopify)
      end
      return unless unsynced_media.any?

      media_input = unsynced_media.map do |media|
        blob = media.image.blob
        wait_until_file_is_available(blob)
        {
          originalSource: blob.url,
          alt: media.alt,
          mediaContentType: "IMAGE"
        }
      end

      api_client = Shopify::ApiClient.new
      created_media = api_client.push_media(shopify_product_id, media_input)

      save_shopify_media_ids(unsynced_media, created_media)
      reorder_media_on_shopify(product, shopify_product_id, api_client)
    end

    def wait_until_file_is_available(blob, timeout: 300)
      Timeout.timeout(timeout) do
        loop do
          break if blob.service.exist?(blob.key)
          sleep 2
        end
      end
    rescue Timeout::Error
      raise "File was not uploaded to R2 in #{timeout} seconds (blob_id: #{blob.id})"
    end

    def save_shopify_media_ids(local_media, shopify_media)
      local_media.zip(shopify_media).each do |local, shopify|
        local.store_infos.create!(
          store_id: shopify["id"],
          store_name: :shopify
        )
      end
    end

    def reorder_media_on_shopify(product, shopify_product_id, api_client)
      all_media = product.media.ordered

      moves = all_media.each_with_index.map do |media, index|
        shopify_info = media.store_infos.find_by(store_name: :shopify)
        next unless shopify_info

        {
          id: shopify_info.store_id,
          newPosition: index
        }
      end.compact

      return if moves.blank?

      api_client.reorder_media(shopify_product_id, moves)
    end
  end
end
