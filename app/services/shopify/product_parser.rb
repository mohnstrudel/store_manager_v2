# frozen_string_literal: true

class Shopify::ProductParser
  include Sanitizable

  def initialize(api_item: {}, title: "")
    @product = api_item
    @title = title.presence || @product["title"]
  end

  def parse
    raise ArgumentError, "api_item cannot be blank" if @product.blank?

    title, franchise, size, shape, brand = parse_product_title

    editions = @product["variants"]["edges"].map do |edge|
      {
        id: edge["node"]["id"],
        title: edge["node"]["title"],
        sku: edge["node"]["sku"],
        options: edge["node"]["selectedOptions"]
      }
    end

    media = @product["media"]["nodes"].map.with_index do |node, index|
      {
        id: node["id"],
        alt: node["alt"],
        url: node["image"]["url"],
        position: index + 1,
        store_info: {
          ext_created_at: node["createdAt"],
          ext_updated_at: node["updatedAt"]
        }
      }
    end

    # Use the first variant's SKU as the product SKU
    sku = @product.dig("variants", "edges", 0, "node", "sku")

    {
      shopify_id: @product["id"],
      store_link: @product["handle"],
      shape:,
      title:,
      franchise:,
      size:,
      brand:,
      sku:,
      media:,
      editions:
    }
  end

  def parse_product_title
    raise ArgumentError, "Product title cannot be blank" if @title.blank?

    shopify_name = smart_titleize(sanitize(@title))

    parts = shopify_name.split("|").map(&:strip)

    if parts[0].include?(" - ")
      franchise, title = parts[0].split(" - ")
    else
      franchise = parts[0]
      title = parts[0]
    end

    size = Size.parse_size(parts[1]) if parts[1]
    shape = parts[1]&.match(/Resin\s+(Statue|Bust)/i)&.[](1) || "Statue"

    brand = parts[-1] if parts.size > 2
    brand = Brand.parse_brand(brand) || brand if brand

    [title, franchise, size, shape.titleize, brand]
  end
end
