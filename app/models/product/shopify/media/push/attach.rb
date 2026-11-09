# frozen_string_literal: true

class Product::Shopify::Media::Push::Attach
  def initialize(product:, product_store_id:, api_client:, new_media:, known_ids:)
    @product = product
    @product_store_id = product_store_id
    @api_client = api_client
    @new_media = new_media
    @known_ids = known_ids
  end

  def call
    attached_nodes = api_client.attach_media(product_store_id, api_input)
    created_nodes = attached_nodes.select { |node| node["id"].present? && known_ids.exclude?(node["id"]) }

    unless created_nodes.size == new_media.size
      raise Shopify::Api::Client::ApiError,
        "Shopify returned #{created_nodes.size} new media after attaching #{new_media.size} images to #{product_store_id}"
    end

    create_many(local_media: new_media, shopify_media: created_nodes)
  end

  private

  attr_reader :product, :product_store_id, :api_client, :new_media, :known_ids

  def api_input
    new_media.map { |media| build_attach_input(media) }
  end

  def build_attach_input(media)
    {
      originalSource: media.image.blob.url,
      alt: media.alt || "#{product.title} image",
      mediaContentType: "IMAGE"
    }
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
