# frozen_string_literal: true

module Shopify
  module Api
    class Client
      attr_reader :graphql_client
      private :graphql_client

      class ApiError < StandardError; end

      class Throttled < ApiError; end

      def initialize
        session = ShopifyAPI::Auth::Session.new(
          shop: ENV.fetch("SHOPIFY_DOMAIN"),
          access_token: ENV.fetch("SHOPIFY_API_TOKEN")
        )
        @graphql_client = ShopifyAPI::Clients::Graphql::Admin.new(session:)
      end

      def fetch_product(product_store_id)
        raise ArgumentError, "Product Shopify ID (store_id) is required" if product_store_id.blank?

        response = execute(
          Shopify::Graphql::ProductQuery.by_id,
          variables: {id: product_store_id},
          operation: "product"
        )
        handle_query_errors(response, resource_name: "product")

        product = response.body.dig("data", "product")
        report_truncated_variants([product])
        product
      end

      def fetch_products(cursor:, batch_size:)
        response = execute(
          Shopify::Graphql::ProductQuery.list,
          variables: {first: Integer(batch_size), after: cursor},
          operation: "products"
        )
        handle_query_errors(response, resource_name: "products")

        page = extract_pagination(response.body["data"], resource_name: "products")
        report_truncated_variants(page[:items])
        page
      end

      def create_product(serialized_product)
        query = Shopify::Graphql::ProductMutation.create(serialized_product)

        response = execute(query, variables: {}, operation: "productCreate")
        handle_mutation_errors(response, "productCreate", query: query)

        response.body.dig("data", "productCreate", "product")
      end

      def update_product(product_store_id, serialized_product)
        query = Shopify::Graphql::ProductMutation.update

        variables = {
          product: serialized_product.merge(id: product_store_id)
        }

        response = execute(query, variables:, operation: "productUpdate")
        handle_mutation_errors(response, "productUpdate", query: query)

        response.body.dig("data", "productUpdate", "product")
      end

      def create_product_options(product_store_id, options)
        query = Shopify::Graphql::ProductMutation.create_options

        variables = {
          productId: product_store_id,
          options: options,
          variantStrategy: "CREATE"
        }

        response = execute(query, variables:, operation: "productOptionsCreate")
        handle_mutation_errors(response, "productOptionsCreate", query: query)

        response.body.dig("data", "productOptionsCreate", "product")
      end

      def fetch_order(order_id)
        raise ArgumentError, "Order ID (sale's store_id) is required" if order_id.blank?

        response = execute(
          Shopify::Graphql::OrderQuery.by_id,
          variables: {id: order_id},
          operation: "order"
        )
        handle_query_errors(response, resource_name: "order")

        order = response.body.dig("data", "order")
        report_truncated_line_items([order])
        order
      end

      def fetch_orders(cursor:, batch_size:)
        response = execute(
          Shopify::Graphql::OrderQuery.list,
          variables: {first: Integer(batch_size), after: cursor},
          operation: "orders"
        )
        handle_query_errors(response, resource_name: "orders")

        page = extract_pagination(response.body["data"], resource_name: "orders")
        report_truncated_line_items(page[:items])
        page
      end

      def attach_media(product_store_id, media_input)
        return [] if media_input.blank?

        query = Shopify::Graphql::MediaMutation.attach

        variables = {
          product: {id: product_store_id},
          media: media_input
        }

        response = execute(query, variables:, operation: "productUpdate")
        handle_mutation_errors(response, "productUpdate", query: query)

        response.body.dig("data", "productUpdate", "product", "media", "nodes")
      end

      def update_media(file_updates)
        return [] if file_updates.blank?

        query = Shopify::Graphql::MediaMutation.update

        variables = {
          files: file_updates
        }

        response = execute(query, variables:, operation: "fileUpdate")
        handle_mutation_errors(response, "fileUpdate", query: query)

        response.body.dig("data", "fileUpdate", "files")
      end

      def reorder_media(product_store_id, moves)
        return if moves.blank?

        query = Shopify::Graphql::MediaMutation.reorder

        variables = {
          id: product_store_id,
          moves: moves
        }

        response = execute(query, variables:, operation: "productReorderMedia")
        handle_mutation_errors(response, "productReorderMedia", query: query)

        response.body.dig("data", "productReorderMedia", "job")
      end

      private

      def execute(query, variables:, operation:)
        response = graphql_client.query(query:, variables:)
        log_query_cost(response, operation:)
        raise Throttled, "Shopify throttled #{operation}" if throttled?(response)

        response
      rescue ShopifyAPI::Errors::HttpResponseError => e
        raise unless e.response.code == 429

        raise Throttled, "Shopify throttled #{operation} with HTTP 429"
      end

      def log_query_cost(response, operation:)
        cost = response.body.dig("extensions", "cost")
        return if cost.blank?

        throttle = cost["throttleStatus"] || {}

        Rails.logger.info(
          "Shopify #{operation} query cost: requested=#{cost["requestedQueryCost"]} " \
          "actual=#{cost["actualQueryCost"]} available=#{throttle["currentlyAvailable"]}/#{throttle["maximumAvailable"]} " \
          "restore_rate=#{throttle["restoreRate"]}"
        )
      end

      def throttled?(response)
        response.body["errors"].to_a.any? { |error| error.dig("extensions", "code") == "THROTTLED" }
      end

      def handle_query_errors(response, resource_name:)
        errors = response.body["errors"]
        return unless errors

        error_messages = errors.pluck("message").join(", ")
        raise ApiError, "Failed to fetch #{resource_name}: #{error_messages}"
      end

      def report_truncated_variants(products)
        report_truncated(products, connection: "variants", description: "variants", owner: "product")
      end

      def report_truncated(records, connection:, description:, owner:)
        truncated_ids = Array(records).filter_map do |record|
          record["id"] if record&.dig(connection, "pageInfo", "hasNextPage")
        end
        return if truncated_ids.empty?

        message = "Shopify #{description} truncated for #{truncated_ids.size} #{owner}(s): #{truncated_ids.join(", ")}"

        Rails.logger.error(message)
        Sentry.capture_message(
          message,
          level: :error,
          tags: {api: "shopify", operation: connection},
          extra: {"#{owner}_ids": truncated_ids}
        )
      end

      def extract_pagination(response_data, resource_name:)
        connection = response_data[resource_name]
        {
          items: connection["edges"].pluck("node"),
          has_next_page: connection["pageInfo"]["hasNextPage"],
          end_cursor: connection["pageInfo"]["endCursor"]
        }
      end

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

      def report_truncated_line_items(orders)
        report_truncated(orders, connection: "lineItems", description: "line items", owner: "order")
      end
    end
  end
end
