class Shopify::ApiClient
  PRODUCT_FIELDS = <<~GQL
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
  GQL

  SALE_FIELDS = <<~GQL
    cancelledAt
    cancelReason
    closed
    closedAt
    confirmed
    createdAt
    displayFinancialStatus
    displayFulfillmentStatus
    fullyPaid
    id
    name
    note
    returnStatus
    statusPageUrl
    totalDiscounts
    totalPrice
    totalShippingPrice
    unpaid
    updatedAt
    phone
    email
    customer {
      id
      lastName
      email
      firstName
      phone
    }
    shippingAddress {
      address1
      address2
      city
      company
      country
      zip
      phone
    }
    lineItems(first: 10) {
      nodes {
        id
        quantity
        originalTotal
        variantTitle
        title
        variant {
          id
          displayName
          product {
            id
          }
        }
        product {
          #{PRODUCT_FIELDS}
        }
      }
    }
  GQL

  def initialize
    session = ShopifyAPI::Auth::Session.new(
      shop: ENV.fetch("SHOPIFY_DOMAIN"),
      access_token: ENV.fetch("SHOPIFY_API_TOKEN")
    )
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session:)
  end

  def pull_product(id)
    raise ArgumentError, "Product ID is required" if id.blank?

    @client.query(
      query: gql_query("product"),
      variables: {id:}
    )
      .body["data"]["product"]
  end

  def pull_order(id)
    raise ArgumentError, "Order ID is required" if id.blank?

    @client.query(
      query: gql_query("order"),
      variables: {id:}
    )
      .body["data"]["order"]
  end

  def pull(resource_name:, cursor:, batch_size:)
    raise ArgumentError, "Name is required" if resource_name.blank?

    response_body = @client.query(
      query: gql_query(resource_name),
      variables: {
        first: batch_size,
        after: cursor
      }
    ).body["data"]

    response_data = response_body[resource_name] || response_body

    {
      items: response_data["edges"].pluck("node"),
      has_next_page: response_data["pageInfo"]["hasNextPage"],
      end_cursor: response_data["pageInfo"]["endCursor"]
    }
  end

  def gql_query(name)
    case name
    when "product"
      product_query
    when "products"
      products_query
    when "order"
      order_query
    when "orders"
      orders_query
    else
      raise ArgumentError, "Invalid query name: #{name}"
    end
  end

  private

  def product_query
    <<~GQL
      query($id: ID!) {
        product(id: $id) {
          #{PRODUCT_FIELDS}
        }
      }
    GQL
  end

  def products_query
    <<~GQL
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
              #{PRODUCT_FIELDS}
            }
          }
        }
      }
    GQL
  end

  def order_query
    <<~GQL
      query($id: ID!) {
        sale(id: $id) {
          #{SALE_FIELDS}
        }
      }
    GQL
  end

  def orders_query
    <<~GQL
      query($first: Int!, $after: String) {
        orders(
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
              #{SALE_FIELDS}
            }
          }
        }
      }
    GQL
  end
end
