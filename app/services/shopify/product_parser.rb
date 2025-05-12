class Shopify::ProductParser
  include Sanitizable

  def initialize(api_product: {}, title: "")
    @product = api_product
    @title = title.presence || @product["title"]
  end

  def parse
    raise ArgumentError, "Product data is required" if @product.blank?
    raise ArgumentError, "Product data must be a Hash" unless @product.is_a?(Hash)

    title, franchise, size, shape, brand = parse_product_title

    variations = @product["variants"]["edges"].map do |edge|
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
      variations:
    }
  end

  def parse_product_title
    raise ArgumentError, "Product title is required" if @title.blank?

    shopify_name = smart_titleize(sanitize(@title))

    parts = shopify_name.split("|").map(&:strip)
    franchise_product = parts[0].split("-").map(&:strip)

    franchise = franchise_product[0]
    title = franchise_product[1] || franchise_product[0]

    size = Size.parse_size(parts[1]) if parts[1]
    shape = parts[1]&.match(/Resin\s+(Statue|Bust)/i)&.[](1) || "Statue"

    brand = Brand.parse_brand(parts[-1])

    [title, franchise, size, shape.titleize, brand]
  end
end
