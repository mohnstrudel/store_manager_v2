# frozen_string_literal: true

class Product::Shopify::Media::Push::Attach
  def initialize(product:, product_store_id:, api_client:, new_media:)
    @product = product
    @product_store_id = product_store_id
    @api_client = api_client
    @new_media = new_media
  end

  def call
    created_media = api_client.attach_media(product_store_id, api_input)
    create_many(local_media: new_media, shopify_media: created_media)
  end

  private

  attr_reader :product, :product_store_id, :api_client, :new_media

  def api_input
    new_media.map { |media| build_attach_input(media) }
  end

  def build_attach_input(media)
    blob = media.image.blob
    wait_until_file_is_available(blob)

    {
      originalSource: blob.url,
      alt: media.alt || "#{product.title} image",
      mediaContentType: "IMAGE"
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

  def create_many(local_media:, shopify_media:)
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
end
