# frozen_string_literal: true

module Shopify
  class PushMediaJob < ApplicationJob
    attr_reader :product, :product_store_id, :api_client, :new_media, :existing_media
    private :product, :product_store_id, :api_client, :new_media, :existing_media

    def perform(product_id, product_store_id)
      @product = Product.for_media_sync.find(product_id)
      @product_store_id = product_store_id
      @api_client = Shopify::Api::Client.new
      @new_media, @existing_media = product.media.partition { |m| m.shopify_info.nil? }

      return unless new_media.any? || existing_media.any?

      attach_new_media if new_media.any?
      update_existing_media if existing_media.any?

      reorder_media_on_shopify
    rescue Shopify::Api::Client::ApiError => e
      handle_shopify_error(e)
    end

    def attach_new_media
      api_input = new_media.map do |media|
        blob = media.image.blob
        wait_until_file_is_available(blob)

        {
          originalSource: blob.url,
          alt: media.alt || "#{product.title} image",
          mediaContentType: "IMAGE"
        }
      end

      created_media = api_client.attach_media(product_store_id, api_input)
      save_shopify_media_ids(new_media, created_media)
    end

    def wait_until_file_is_available(blob, timeout = 600, interval = 2)
      deadline = Time.zone.now + timeout

      loop do
        return if blob.service.exist?(blob.key)
        remaining = deadline - Time.zone.now
        break if remaining <= 0
        sleep [interval, remaining].min + rand(0.0..0.3)
      end

      raise "File was not uploaded to R2 in #{timeout} seconds (blob_id: #{blob.id})"
    end

    def save_shopify_media_ids(local_media, shopify_media)
      local_media.zip(shopify_media).each do |local, shopify|
        local.store_infos.create!(
          store_id: shopify["id"],
          store_name: "shopify",
          checksum: local.image.blob.checksum,
          alt_text: local.alt,
          ext_created_at: shopify["createdAt"],
          ext_updated_at: shopify["updatedAt"],
          push_time: Time.zone.now
        )
      end
    end

    def update_existing_media
      changed = []
      api_input = []

      existing_media.each do |media|
        next unless relevant_for_update?(media)

        changed << media
        api_input << prepare_api_input_for(media)
      end

      return if api_input.empty?

      api_response = api_client.update_media(api_input)
      update_shopify_store_infos(changed, api_response)
    end

    def relevant_for_update?(media)
      shopify_info = media.shopify_info
      shopify_info.present? && media_changed?(media, shopify_info)
    end

    def media_changed?(media, shopify_info)
      media.image.blob.checksum != shopify_info.checksum ||
        media.alt != shopify_info.alt_text
    end

    def prepare_api_input_for(media)
      blob = media.image.blob
      wait_until_file_is_available(blob)

      {
        id: media.shopify_info.store_id,
        originalSource: blob.url,
        alt: media.alt.presence || "#{@product.title} image"
      }
    end

    def update_shopify_store_infos(changed_media, api_response)
      changed_media.each do |media|
        shopify_info = media.shopify_info
        response_item = api_response.find { |f| f["id"] == shopify_info.store_id }

        shopify_info.update!(
          checksum: media.image.blob.checksum,
          alt_text: media.alt,
          ext_created_at: response_item&.dig("createdAt"),
          ext_updated_at: response_item&.dig("updatedAt"),
          push_time: Time.zone.now
        )
      end
    end

    def reorder_media_on_shopify
      media = product.media.ordered.preload(:store_infos)
      api_product_response = api_client.fetch_product(product_store_id)

      shopify_positions = api_product_response["media"]["nodes"]
        .each_with_index
        .to_h { |node, index| [node["id"], index] }

      # We only need changed positions
      moves = position_changes(shopify_positions, media)
      return if moves.blank?

      api_client.reorder_media(product_store_id, moves)
    end

    def position_changes(shopify_positions, media)
      media.each_with_index.filter_map do |media_item, our_position|
        next unless (shopify_info = media_item.shopify_info)

        store_id = shopify_info.store_id
        shopify_position = shopify_positions[store_id]

        next if shopify_position == our_position

        {
          id: store_id,
          newPosition: our_position.to_s
        }
      end
    end

    def handle_shopify_error(error)
      return unless error.message.include?("Product does not exist")

      product.shopify_info.destroy!

      product.media.joins(:store_infos)
        .where(store_infos: {store_name: "shopify"})
        .find_each do |media|
          media.store_infos.where(store_name: "shopify").destroy_all
        end
    end
  end
end
