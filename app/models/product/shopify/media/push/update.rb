# frozen_string_literal: true

class Product::Shopify::Media::Push::Update
  def initialize(product:, api_client:, existing_media:)
    @product = product
    @api_client = api_client
    @existing_media = existing_media
  end

  def call
    changed_media = []
    api_input = []

    existing_media.each do |media|
      next unless relevant_for_update?(media)

      changed_media << media
      api_input << build_update_input(media)
    end

    return if api_input.empty?

    api_response = api_client.update_media(api_input)
    update_shopify_store_infos(changed_media:, api_response:)
  end

  private

  attr_reader :product, :api_client, :existing_media

  def relevant_for_update?(media)
    shopify_info = media.shopify_info
    shopify_info.present? && media_changed?(media, shopify_info)
  end

  def media_changed?(media, shopify_info)
    media.image.blob.checksum != shopify_info.checksum ||
      media.alt != shopify_info.alt_text
  end

  def build_update_input(media)
    blob = media.image.blob
    wait_until_file_is_available(blob)

    {
      id: media.shopify_info.store_id,
      originalSource: blob.url,
      alt: media.alt.presence || "#{product.title} image"
    }
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
