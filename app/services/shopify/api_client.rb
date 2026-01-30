# frozen_string_literal: true

class ShopifyApiError < StandardError; end

class Shopify::ApiClient
  PRODUCT_FIELDS = <<~GQL
    id
    title
    handle
    createdAt
    updatedAt
    media(first: 20) {
      nodes {
        ... on MediaImage {
          id
          alt
          status
          fileStatus
          createdAt
          updatedAt
          image {
            url
          }
        }
      }
    }
    variants(first: 10) {
      edges {
        node {
          id
          title
          price
          sku
          createdAt
          updatedAt
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
      createdAt
      updatedAt
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

    response = @client.query(
      query: gql_query(resource_name),
      variables: {
        first: Integer(batch_size),
        after: cursor
      }
    )

    errors = response.body["errors"]
    if errors
      error_messages = errors.pluck("message").join(", ")
      raise ShopifyApiError, "Failed to fetch #{resource_name}: #{error_messages}"
    end

    response_body = response.body["data"]
    response_data = response_body[resource_name] || response_body

    {
      items: response_data["edges"].pluck("node"),
      has_next_page: response_data["pageInfo"]["hasNextPage"],
      end_cursor: response_data["pageInfo"]["endCursor"]
    }
  end

  def create_product(serialized_product)
    query = <<~GQL
      mutation {
        productCreate(product: #{serialized_product}) {
          product {
            id
            title
            handle
          }
          userErrors {
            field
            message
          }
        }
      }
    GQL

    response = @client.query(query:)

    handle_shopify_mutation_errors(query, response, "productCreate")

    response.body.dig("data", "productCreate", "product")
  end

  def product_update(shopify_product_id, serialized_product)
    query = <<~GQL
      mutation productUpdate($product: ProductUpdateInput!) {
        productUpdate(product: $product) {
          product {
            id
            title
            handle
            media(first: 20) {
              nodes {
                id
              }
            }
          }
          userErrors {
            field
            message
          }
        }
      }
    GQL

    variables = {
      product: serialized_product.merge(id: shopify_product_id)
    }

    response = @client.query(query:, variables:)

    handle_shopify_mutation_errors(query, response, "productUpdate")

    response.body.dig("data", "productUpdate", "product")
  end

  def create_product_options(shopify_product_id, serialized_options)
    query = <<~GQL
      mutation createOptions($productId: ID!, $options: [OptionCreateInput!]!, $variantStrategy: ProductOptionCreateVariantStrategy) {
        productOptionsCreate(productId: $productId, options: $options, variantStrategy: $variantStrategy) {
          userErrors {
            field
            message
          }
          product {
            id
            variants(first: 10) {
              nodes {
                id
                title
                selectedOptions {
                  name
                  value
                }
              }
            }
            options {
              id
              name
              values
              position
              optionValues {
                id
                name
                hasVariants
              }
            }
          }
        }
      }
    GQL

    response = @client.query(
      query:,
      variables: {
        productId: shopify_product_id,
        options: serialized_options,
        variantStrategy: "CREATE"
      }
    )

    handle_shopify_mutation_errors(query, response, "productOptionsCreate")

    response.body.dig("data", "productOptionsCreate", "product")
  end

  def attach_media(shopify_product_id, media_input)
    return [] if media_input.blank?

    query = <<~GQL
      mutation($product: ProductUpdateInput!, $media: [CreateMediaInput!]) {
        productUpdate(product: $product, media: $media) {
          product {
            id
            media(first: 20) {
              nodes {
                ... on MediaImage {
                  id
                  alt
                  status
                  fileStatus
                  createdAt
                  updatedAt
                }
              }
            }
          }
          userErrors {
            field
            message
          }
        }
      }
    GQL

    variables = {
      product: {id: shopify_product_id},
      media: media_input
    }

    response = @client.query(query:, variables:)

    handle_shopify_mutation_errors(query, response, "productUpdate")

    media_nodes = response.body.dig("data", "productUpdate", "product", "media", "nodes")
    wait_for_media_ready(media_nodes)
    media_nodes
  end

  def wait_for_media_ready(media_nodes, timeout: 300, interval: 2)
    deadline = Time.zone.now + timeout

    media_nodes.each do |media_node|
      loop do
        status = media_node["status"]
        file_status = media_node["fileStatus"]

        break if status == "READY" || file_status == "READY"

        remaining = deadline - Time.zone.now
        raise "Media #{media_node["id"]} failed to become ready within #{timeout} seconds" if remaining <= 0

        sleep [interval, remaining].min

        # Refresh the media status
        updated_status = query_media_status(media_node["id"])
        media_node.merge!(updated_status) if updated_status
      end
    end
  end

  def query_media_status(media_id)
    query = <<~GQL
      query($id: ID!) {
        node(id: $id) {
          ... on MediaImage {
            id
            status
            fileStatus
          }
        }
      }
    GQL

    response = @client.query(query:, variables: {id: media_id})
    response.body.dig("data", "node")
  end

  def update_media(file_updates)
    return [] if file_updates.blank?

    query = <<~GQL
      mutation($files: [FileUpdateInput!]!) {
        fileUpdate(files: $files) {
          files {
            ... on MediaImage {
              id
              alt
              createdAt
              updatedAt
              image {
                url
              }
            }
          }
          userErrors {
            field
            message
          }
        }
      }
    GQL

    variables = {
      files: file_updates
    }

    response = @client.query(query:, variables:)

    handle_shopify_mutation_errors(query, response, "fileUpdate")

    response.body.dig("data", "fileUpdate", "files")
  end

  def reorder_media(shopify_product_id, moves)
    return if moves.blank?

    query = <<~GQL
      mutation($id: ID!, $moves: [MoveInput!]!) {
        productReorderMedia(id: $id, moves: $moves) {
          job {
            id
            done
          }
          mediaUserErrors {
            field
            message
          }
        }
      }
    GQL

    variables = {
      id: shopify_product_id,
      moves: moves
    }

    response = @client.query(query:, variables:)

    handle_shopify_mutation_errors(query, response, "productReorderMedia")

    response.body.dig("data", "productReorderMedia", "job")
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
      query ProductById($id: ID!) {
        product(id: $id) {
          #{PRODUCT_FIELDS}
        }
      }
    GQL
  end

  def products_query
    <<~GQL
      query FetchProducts($first: Int!, $after: String) {
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

  def handle_shopify_mutation_errors(query, response, operation_name)
    api_errors = response.body.dig("errors")
    user_errors = response.body.dig("data", operation_name, "userErrors")
    media_user_errors = response.body.dig("data", operation_name, "mediaUserErrors")
    errors = user_errors || media_user_errors

    if api_errors || errors&.any?
      error_messages = if api_errors
        api_errors.pluck("message").join(", ")
      else
        errors.pluck("message").join(", ")
      end

      Sentry.capture_message(
        "Shopify #{operation_name} failed: #{error_messages}",
        level: :error,
        tags: {
          api: "shopify",
          operation: operation_name
        },
        extra: {
          query:,
          shopify_errors: api_errors
        }
      )

      raise ShopifyApiError, "Failed to call the #{operation_name} API mutation: #{error_messages}"
    end
  end
end
