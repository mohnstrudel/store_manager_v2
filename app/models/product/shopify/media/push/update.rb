# frozen_string_literal: true

class Product::Shopify::Media::Push::Update
  def initialize(product:, api_client:, existing_media:)
    @product = product
    @api_client = api_client
    @existing_media = existing_media
  end

  def call
    changed_media = existing_media.select { |media| changed?(media) }
    return if changed_media.empty?

    Product::Shopify::Media::Push.ensure_files_stored(changed_media.select { |media| checksum_changed?(media) })
    api_response = api_client.update_media(changed_media.map { |media| build_update_input(media) })
    update_shopify_store_infos(changed_media:, api_response:)
  end

  private

  attr_reader :product, :api_client, :existing_media

  def changed?(media)
    checksum_changed?(media) || alt_changed?(media)
  end

  def checksum_changed?(media)
    media.image.blob.checksum != media.shopify_info.checksum
  end

  def alt_changed?(media)
    media.alt.presence != media.shopify_info.alt_text.presence
  end

  def build_update_input(media)
    input = {id: media.shopify_info.store_id, alt: media.alt.presence || "#{product.title} image"}
    return input unless checksum_changed?(media)

    input.merge(originalSource: media.image.blob.url)
  end

  def update_shopify_store_infos(changed_media:, api_response:)
    changed_media.each do |media|
      shopify_info = media.shopify_info
      response_item = api_response.find { |item| item["id"] == shopify_info.store_id }

      shopify_info.update!(
        checksum: media.image.blob.checksum,
        alt_text: media.alt,
        ext_created_at: response_item&.dig("createdAt"),
        ext_updated_at: response_item&.dig("updatedAt"),
        push_time: Time.zone.now
      )
    end
  end
end
