# frozen_string_literal: true

class Product::Shopify::Parser
  include Sanitizable

  attr_reader :payload, :parsed_editions, :parsed_media, :parsed_sku, :parsed_title
  private :payload, :parsed_editions, :parsed_media, :parsed_sku, :parsed_title

  def self.parse(payload)
    raise ArgumentError, "Payload cannot be blank" if payload.blank?
    return payload if payload.key?(:store_id)

    new(payload).parse
  end

  def initialize(payload)
    @payload = payload
  end

  def parse
    parse_shopify_title
    parse_sku
    parse_media
    parse_editions

    {
      brand: parsed_title[:brand],
      description: payload["descriptionHtml"].presence,
      editions: parsed_editions,
      franchise: parsed_title[:franchise],
      media: parsed_media,
      shape: parsed_title[:shape],
      size: parsed_title[:size],
      sku: parsed_sku,
      store_id: payload["id"],
      store_info: {
        ext_created_at: payload["createdAt"],
        ext_updated_at: payload["updatedAt"]
      },
      store_link: payload["handle"],
      tags: payload["tags"] || [],
      title: parsed_title[:title]
    }.compact_blank
  end

  private

  def parse_shopify_title
    prepared_title = smart_titleize(sanitize(payload["title"]))
    parts = prepared_title.split("|").map(&:strip)

    franchise, product_name = if parts[0].include?(" - ")
      parts[0].split(" - ")
    else
      [parts[0], parts[0]]
    end

    size = Size.parse_size(parts[1]) if parts[1]
    shape = parts[1]&.match(/Resin\s+(Statue|Bust)/i)&.[](1) || "Statue"

    potential_brand = parts[-1] if parts.size > 2
    brand = Brand.parse_brand(potential_brand) || potential_brand if potential_brand

    @parsed_title = {
      brand:,
      franchise:,
      shape: shape.titleize,
      size:,
      title: product_name
    }
  end

  def parse_sku
    @parsed_sku = payload.dig("variants", "edges", 0, "node", "sku") || generate_sku
  end

  def generate_sku
    "#{payload["title"].parameterize}-#{Random.alphanumeric(4)}"
  end

  def parse_media
    @parsed_media = payload.dig("media", "nodes")&.map&.with_index do |node, index|
      {
        key: node["id"].presence || node.dig("image", "url").presence || "media:#{index}",
        id: node["id"],
        alt: node["alt"],
        url: node.dig("image", "url"),
        position: index,
        store_info: {
          ext_created_at: node["createdAt"],
          ext_updated_at: node["updatedAt"]
        }
      }
    end || []
  end

  def parse_editions
    variants = payload.dig("variants", "edges") || []

    if (is_single_variant = variants.size == 1)
      @parsed_editions = [build_edition_data(variants.first["node"], is_single_variant:)]
      return
    end

    @parsed_editions = variants.map { |edge| build_edition_data(edge["node"]) }
  end

  def build_edition_data(variant, is_single_variant: false)
    inventory_item = variant["inventoryItem"] || {}

    {
      store_id: variant["id"],
      title: variant["title"],
      sku: variant["sku"],
      selling_price: variant["price"],
      purchase_cost: inventory_item.dig("unitCost", "amount"),
      weight: inventory_item.dig("measurement", "weight", "value"),
      options: parse_options(variant["selectedOptions"]),
      is_single_variant:,
      store_info: {
        ext_created_at: variant["createdAt"],
        ext_updated_at: variant["updatedAt"]
      }.compact
    }.compact
  end

  def parse_options(options)
    options&.map do |option|
      {name: option["name"], value: option["value"]}
    end || []
  end
end
