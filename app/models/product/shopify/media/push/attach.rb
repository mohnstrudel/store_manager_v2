# frozen_string_literal: true

class Product::Shopify::Media::Push::Attach
  def initialize(product:, product_store_id:, api_client:, new_media:, nodes:, claimed_ids:)
    @product = product
    @product_store_id = product_store_id
    @api_client = api_client
    @new_media = new_media
    @nodes = nodes
    @claimed_ids = claimed_ids
  end

  def call
    adopted = adopt_unclaimed_nodes
    linked = adopted + attach_remaining(adopted.map(&:first))
    create_many(linked)
    linked.size
  end

  private

  attr_reader :product, :product_store_id, :api_client, :new_media, :nodes, :claimed_ids

  def adopt_unclaimed_nodes
    candidates = nodes.select { |node| adoptable?(node) }

    new_media.filter_map do |media|
      index = candidates.index { |node| same_alt?(node, media) }
      [media, candidates.delete_at(index)] if index
    end
  end

  def adoptable?(node)
    node["id"].present? && claimed_ids.exclude?(node["id"]) && node["status"] != "FAILED"
  end

  def same_alt?(node, media)
    node["alt"].to_s.squish == attach_alt(media).squish
  end

  def attach_alt(media)
    media.alt.presence || "#{product.title} image"
  end

  def attach_remaining(adopted_media)
    remaining = new_media - adopted_media
    return [] if remaining.empty?

    attached_nodes = api_client.attach_media(product_store_id, remaining.map { |media| build_attach_input(media) })
    created_nodes = attached_nodes.select { |node| node["id"].present? && known_ids.exclude?(node["id"]) }

    unless created_nodes.size == remaining.size
      raise Product::Shopify::Media::Push::AttachMismatch,
        "Shopify returned #{created_nodes.size} new media after attaching #{remaining.size} images to #{product_store_id} (unknown IDs: #{created_nodes.pluck("id").join(", ").presence || "none"})"
    end

    remaining.zip(created_nodes)
  end

  def build_attach_input(media)
    {
      originalSource: media.image.blob.url,
      alt: attach_alt(media),
      mediaContentType: "IMAGE"
    }
  end

  def known_ids
    @known_ids ||= nodes.filter_map { |node| node["id"] }
  end

  def create_many(pairs)
    pairs.each do |local, shopify|
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
