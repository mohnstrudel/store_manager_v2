# frozen_string_literal: true

# Shopify::Api::Client
#
# For executing GraphQL queries against the Shopify Admin API.
# Handles session management, query execution, and error reporting.
#
# Usage:
#   client = Shopify::Api::Client.new
#   product = client.fetch_product("gid://shopify/Product/123")
#   products = client.fetch_products(cursor: nil, batch_size: 50)
#
module Shopify
  module Api
    class Client
      attr_reader :graphql_client
      private :graphql_client

      class ApiError < StandardError; end

      # Initialize a new API client with Shopify credentials.
      #
      # @return [Shopify::Api::Client]
      def initialize
        session = ShopifyAPI::Auth::Session.new(
          shop: ENV.fetch("SHOPIFY_DOMAIN"),
          access_token: ENV.fetch("SHOPIFY_API_TOKEN")
        )
        @graphql_client = ShopifyAPI::Clients::Graphql::Admin.new(session:)
      end

      # Fetch a single product by ID.
      #
      # @param product_store_id [String] The Shopify product ID (GID)
      # @return [Hash] The product data
      # @raise [ArgumentError] if product_store_id is blank
      def fetch_product(product_store_id)
        raise ArgumentError, "Product Shopify ID (store_id) is required" if product_store_id.blank?

        response = graphql_client.query(
          query: Shopify::Graphql::ProductQuery.by_id,
          variables: {id: product_store_id}
        )
        handle_query_errors(response, resource_name: "product")
        response.body.dig("data", "product")
      end

      # Fetch products with pagination.
      #
      # @param cursor [String, nil] The pagination cursor
      # @param batch_size [Integer] The number of items to fetch
      # @return [Hash] Hash with :items, :has_next_page, and :end_cursor keys
      def fetch_products(cursor:, batch_size:)
        response = graphql_client.query(
          query: Shopify::Graphql::ProductQuery.list,
          variables: {
            first: Integer(batch_size),
            after: cursor
          }
        )
        handle_query_errors(response, resource_name: "products")

        extract_pagination(response.body["data"], resource_name: "products")
      end

      # Create a new product.
      #
      # @param serialized_product [String] The serialized product input (as a GraphQL string)
      # @return [Hash] The created product data
      def create_product(serialized_product)
        query = Shopify::Graphql::ProductMutation.create(serialized_product)

        response = graphql_client.query(query: query, variables: {})
        handle_mutation_errors(response, "productCreate", query: query)

        response.body.dig("data", "productCreate", "product")
      end

      # Update an existing product.
      #
      # @param product_store_id [String] The Shopify product ID (GID)
      # @param serialized_product [Hash] The serialized product attributes
      # @return [Hash] The updated product data
      def update_product(product_store_id, serialized_product)
        query = Shopify::Graphql::ProductMutation.update

        variables = {
          product: serialized_product.merge(id: product_store_id)
        }

        response = graphql_client.query(query: query, variables:)
        handle_mutation_errors(response, "productUpdate", query: query)

        response.body.dig("data", "productUpdate", "product")
      end

      # Create product options (variants).
      #
      # @param product_store_id [String] The Shopify product ID (GID)
      # @param options [Array<Hash>] Array of option definitions
      # @return [Hash] The updated product data with options and variants
      def create_product_options(product_store_id, options)
        query = Shopify::Graphql::ProductMutation.create_options

        variables = {
          productId: product_store_id,
          options: options,
          variantStrategy: "CREATE"
        }

        response = graphql_client.query(query: query, variables:)
        handle_mutation_errors(response, "productOptionsCreate", query: query)

        response.body.dig("data", "productOptionsCreate", "product")
      end

      # Fetch a single order by ID.
      #
      # @param order_id [String] The Shopify order ID (GID)
      # @return [Hash] The order data
      # @raise [ArgumentError] if order_id is blank
      def fetch_order(order_id)
        raise ArgumentError, "Order ID (sale's store_id) is required" if order_id.blank?

        response = graphql_client.query(
          query: Shopify::Graphql::OrderQuery.by_id,
          variables: {id: order_id}
        )
        handle_query_errors(response, resource_name: "order")
        response.body.dig("data", "order")
      end

      # Fetch orders with pagination.
      #
      # @param cursor [String, nil] The pagination cursor
      # @param batch_size [Integer] The number of items to fetch
      # @return [Hash] Hash with :items, :has_next_page, and :end_cursor keys
      def fetch_orders(cursor:, batch_size:)
        response = graphql_client.query(
          query: Shopify::Graphql::OrderQuery.list,
          variables: {
            first: Integer(batch_size),
            after: cursor
          }
        )
        handle_query_errors(response, resource_name: "orders")

        extract_pagination(response.body["data"], resource_name: "orders")
      end

      # Attach media to a product.
      #
      # @param product_store_id [String] The Shopify product ID (GID)
      # @param media_input [Array<Hash>] Array of media inputs
      # @return [Array<Hash>] The created media nodes
      def attach_media(product_store_id, media_input)
        return [] if media_input.blank?

        query = Shopify::Graphql::MediaMutation.attach

        variables = {
          product: {id: product_store_id},
          media: media_input
        }

        response = graphql_client.query(query: query, variables:)
        handle_mutation_errors(response, "productUpdate", query: query)

        media_nodes = response.body.dig("data", "productUpdate", "product", "media", "nodes")
        wait_until_media_ready(media_nodes)
        media_nodes
      end

      # Update media files.
      #
      # @param file_updates [Array<Hash>] Array of file update inputs
      # @return [Array<Hash>] The updated file data
      def update_media(file_updates)
        return [] if file_updates.blank?

        query = Shopify::Graphql::MediaMutation.update

        variables = {
          files: file_updates
        }

        response = graphql_client.query(query: query, variables:)
        handle_mutation_errors(response, "fileUpdate", query: query)

        response.body.dig("data", "fileUpdate", "files")
      end

      # Reorder media on a product.
      #
      # @param product_store_id [String] The Shopify product ID (GID)
      # @param moves [Array<Hash>] Array of move operations
      # @return [Hash] The job data
      def reorder_media(product_store_id, moves)
        return if moves.blank?

        query = Shopify::Graphql::MediaMutation.reorder

        variables = {
          id: product_store_id,
          moves: moves
        }

        response = graphql_client.query(query: query, variables:)
        handle_mutation_errors(response, "productReorderMedia", query: query)

        response.body.dig("data", "productReorderMedia", "job")
      end

      private

      # Handle errors from a query response.
      #
      # @param response [Object] The response object from the API client
      # @param resource_name [String] The name of the resource being queried
      # @raise [ApiError] if errors are present
      def handle_query_errors(response, resource_name:)
        errors = response.body["errors"]
        return unless errors

        error_messages = errors.pluck("message").join(", ")
        raise ApiError, "Failed to fetch #{resource_name}: #{error_messages}"
      end

      # Handle errors from a mutation response.
      #
      # @param response [Object] The response object from the API client
      # @param operation_name [String] The name of the mutation operation
      # @param query [String] The query string (for error reporting)
      # @raise [ApiError] if errors are present
      def handle_mutation_errors(response, operation_name, query:)
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

          raise ApiError, "Failed to call the #{operation_name} API mutation: #{error_messages}"
        end
      end

      # Extract paginated items from a connection response.
      #
      # @param response_data [Hash] The response data containing the connection
      # @param resource_name [String] The name of the resource connection
      # @return [Hash] Hash with :items, :has_next_page, and :end_cursor keys
      def extract_pagination(response_data, resource_name:)
        connection = response_data[resource_name]
        {
          items: connection["edges"].pluck("node"),
          has_next_page: connection["pageInfo"]["hasNextPage"],
          end_cursor: connection["pageInfo"]["endCursor"]
        }
      end

      # Wait for media to become ready.
      #
      # @param media_nodes [Array<Hash>] The media nodes to wait for
      # @param timeout [Integer] Maximum time to wait in seconds
      # @param interval [Integer] Check interval in seconds
      def wait_until_media_ready(media_nodes, timeout: 300, interval: 2)
        deadline = Time.zone.now + timeout

        media_nodes.each do |media_node|
          loop do
            status = media_node["status"]
            file_status = media_node["fileStatus"]

            break if status == "READY" || file_status == "READY"

            remaining = deadline - Time.zone.now
            raise ApiError, "Media #{media_node["id"]} failed to become ready within #{timeout} seconds" if remaining <= 0

            sleep [interval, remaining].min

            # Refresh the media status
            updated_status = query_media_status(media_node["id"])
            media_node.merge!(updated_status) if updated_status
          end
        end
      end

      # Query media status.
      #
      # @param media_id [String] The media ID to query
      # @return [Hash, nil] The media status data
      def query_media_status(media_id)
        query = Shopify::Graphql::MediaMutation.status_query

        response = graphql_client.query(query: query, variables: {id: media_id})
        response.body.dig("data", "node")
      end
    end
  end
end
