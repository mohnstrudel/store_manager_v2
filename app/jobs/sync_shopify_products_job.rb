class SyncShopifyProductsJob < ApplicationJob
  queue_as :default

  include Sanitizable

  PRODUCTS_QUERY = <<~GQL
    query($first: Int!, $after: String) {
      products(
        first: $first,
        after: $after,
        sortKey: CREATED_AT,
        reverse: true
      ) {
        pageInfo {
          hasNextPage
          endCursor
        }
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

  BATCH_SIZE = 250

  def perform(cursor = nil, attempts = 0)
    response_data = fetch_shopify_products(cursor)

    parsed_products = response_data[:products]
      .map { |api_product| parse(api_product) }
      .compact_blank

    parsed_products.each do |parsed_product|
      product = find_or_create_product(parsed_product)

      next if product.blank?

      SyncShopifyVariationsJob.perform_later(
        product,
        parsed_product[:variations]
      )

      SyncShopifyImagesJob
        .perform_later(
          product,
          parsed_product[:images]
        )
    end

    if response_data[:has_next_page]
      SyncShopifyProductsJob
        .set(wait: 1.second)
        .perform_later(response_data[:end_cursor])
    end
  rescue ShopifyAPI::Errors::HttpResponseError => e
    if e.code == 429 # Rate limit error
      # Wait and retry with a linear backoff pattern
      retry_delay = attempts * 5 + 5
      SyncShopifyProductsJob
        .set(wait: retry_delay.seconds)
        .perform_later(cursor, attempts + 1)
    else
      raise e
    end
  end

  private

  def fetch_shopify_products(cursor = nil)
    session = ShopifyAPI::Auth::Session.new(
      shop: ENV.fetch("SHOPIFY_DOMAIN"),
      access_token: ENV.fetch("SHOPIFY_API_TOKEN")
    )
    client = ShopifyAPI::Clients::Graphql::Admin.new(session:)
    response = client.query(
      query: PRODUCTS_QUERY,
      variables: {first: BATCH_SIZE, after: cursor}
    )
    data = response.body["data"]["products"]

    {
      products: data["edges"].pluck("node"),
      has_next_page: data["pageInfo"]["hasNextPage"],
      end_cursor: data["pageInfo"]["endCursor"]
    }
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

    if parsed_product[:brand].present?
      brand = Brand.find_or_create_by(title: parsed_product[:brand])
    end

    product_core_attributes = {
      title: parsed_product[:title],
      franchise: Franchise.find_or_create_by(title: parsed_product[:franchise]),
      shape: Shape.find_or_create_by(title: parsed_product[:shape])
    }

    product = synced_product || (brand ?
      brand.products.find_or_initialize_by(product_core_attributes) :
      Product.find_or_initialize_by(product_core_attributes))

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

    ActiveRecord::Base.transaction do
      product.save!
      product.update_full_title
    end

    product
  end
end
