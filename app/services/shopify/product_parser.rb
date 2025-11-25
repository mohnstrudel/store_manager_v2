class Shopify::ProductParser
  include Sanitizable

  def initialize(api_item: {}, title: "")
    raise ArgumentError, "api_item must be a Hash" unless api_item.is_a?(Hash)
    raise ArgumentError, "Product title must be a String" unless title.is_a?(String)
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
        options: edge["node"]["selectedOptions"]
      }
    end

    {
      shopify_id: @product["id"],
      store_link: @product["handle"],
      shape:,
      title:,
      franchise:,
      size:,
      brand:,
      images: @product["images"]["edges"].pluck("node"),
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
