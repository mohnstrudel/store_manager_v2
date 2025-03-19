class SyncShopifyProductsJob < ApplicationJob
  queue_as :default

  include Sanitizable

  PRODUCTS_QUERY = <<~GQL
    query($first: Int!) {
      products(first: $first, sortKey: CREATED_AT, reverse: true) {
        edges {
          node {
            id
            title
            handle
            images(first: 10) {
              edges {
                node {
                  src
                }
              }
            }
            variants(first: 10) {
              edges {
                node {
                  id
                  title
                  selectedOptions {
                    value
                    name
                  }
                }
              }
            }
          }
        }
      }
    }
  GQL

  BATCH_SIZE = 5

  def perform
    parsed_products = get_shopify_products
      .map { |api_product| parse(api_product) }
      .compact_blank

    parsed_products.each do |parsed_product|
      product = find_or_create_product(parsed_product)

      SyncShopifyVariationsJob.perform_later(
        product,
        parsed_product[:variations]
      )

      SyncShopifyImagesJob.perform_later(
        product,
        parsed_product[:images]
      )
    end
  end

  private

  def get_shopify_products
    session = ShopifyAPI::Auth::Session.new(
      shop: ENV.fetch("SHOPIFY_DOMAIN"),
      access_token: ENV.fetch("SHOPIFY_API_TOKEN")
    )
    client = ShopifyAPI::Clients::Graphql::Admin.new(session:)

    response = client.query(
      query: PRODUCTS_QUERY,
      variables: {first: BATCH_SIZE}
    )

    response.body["data"]["products"]["edges"].pluck("node")
  end

  def parse(shopify_product)
    title, franchise, size, shape, brand = parse_product_title(
      shopify_product["title"]
    )

    variations = shopify_product["variants"]["edges"].map do |edge|
      {
        id: edge["node"]["id"],
        title: edge["node"]["title"],
        options: edge["node"]["selectedOptions"]
      }
    end

    {
      shopify_id: shopify_product["id"],
      store_link: shopify_product["handle"],
      shape:,
      title:,
      franchise:,
      size:,
      brand:,
      images: shopify_product["images"]["edges"].pluck("node"),
      variations:
    }
  end

  def parse_product_title(title)
    shopify_name = smart_titleize(sanitize(title))

    parts = shopify_name.split("|").map(&:strip)
    franchise_product = parts[0].split("-").map(&:strip)

    franchise = franchise_product[0]
    title = franchise_product[1] || franchise_product[0]

    size = Size.parse_size(parts[1]) if parts[1]
    shape = parts[1]&.match(/Resin\s+(Statue|Bust)/i)&.[](1) || "Statue"

    brand = Brand.parse_brand(parts[-1])

    [title, franchise, size, shape.titleize, brand]
  end

  def find_or_create_product(parsed_product)
    return if parsed_product.blank?

    synced_product = Product.find_by(shopify_id: parsed_product[:shopify_id])

    brand = Brand.find_or_create_by(title: parsed_product[:brand])

    product_core_attributes = {
      title: parsed_product[:title],
      franchise: Franchise.find_or_create_by(title: parsed_product[:franchise]),
      shape: Shape.find_or_create_by(title: parsed_product[:shape])
    }

    product = synced_product || (brand ?
      brand.products.find_or_initialize_by(product_core_attributes) :
      Product.initialize_by(product_core_attributes)
                                )

    product.assign_attributes(
      shopify_id: parsed_product[:shopify_id],
      store_link: parsed_product[:store_link],
      **product_core_attributes
    )

    if brand && product.brands.find_by(
      title: parsed_product[:brand]
    ).nil?
      product.brands << brand
    end

    if parsed_product[:size] && product.sizes.find_by(
      value: parsed_product[:size]
    ).nil?
      product.sizes << Size.find_or_create_by(value: parsed_product[:size])
    end

    product.save
    product.set_full_title if synced_product
    product
  end
end
