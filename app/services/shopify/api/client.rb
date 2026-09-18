# frozen_string_literal: true

module Shopify
  module Api
    class Client
      attr_reader :graphql_client
      private :graphql_client

      class ApiError < StandardError; end

      def initialize
        session = ShopifyAPI::Auth::Session.new(
          shop: ENV.fetch("SHOPIFY_DOMAIN"),
          access_token: ENV.fetch("SHOPIFY_API_TOKEN")
        )
        @graphql_client = ShopifyAPI::Clients::Graphql::Admin.new(session:)
      end

      def fetch_product(product_store_id)
        raise ArgumentError, "Product Shopify ID (store_id) is required" if product_store_id.blank?

        response = graphql_client.query(
          query: Shopify::Graphql::ProductQuery.by_id,
          variables: {id: product_store_id}
        )
        handle_query_errors(response, resource_name: "product")
        response.body.dig("data", "product")
      end

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

      def create_product(serialized_product)
        query = Shopify::Graphql::ProductMutation.create(serialized_product)

        response = graphql_client.query(query: query, variables: {})
        handle_mutation_errors(response, "productCreate", query: query)

        response.body.dig("data", "productCreate", "product")
      end

      def update_product(product_store_id, serialized_product)
        query = Shopify::Graphql::ProductMutation.update

        variables = {
          product: serialized_product.merge(id: product_store_id)
        }

        response = graphql_client.query(query: query, variables:)
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

        response = graphql_client.query(query: query, variables:)
        handle_mutation_errors(response, "productOptionsCreate", query: query)

        response.body.dig("data", "productOptionsCreate", "product")
      end

      def fetch_order(order_id)
        raise ArgumentError, "Order ID (sale's store_id) is required" if order_id.blank?

        response = graphql_client.query(
          query: Shopify::Graphql::OrderQuery.by_id,
          variables: {id: order_id}
        )
        log_query_cost(response, operation: "order")
        handle_query_errors(response, resource_name: "order")

        order = response.body.dig("data", "order")
        report_truncated_line_items([order])
        order
      end

      def fetch_orders(cursor:, batch_size:)
        response = graphql_client.query(
          query: Shopify::Graphql::OrderQuery.list,
          variables: {
            first: Integer(batch_size),
            after: cursor
          }
        )
        query_cost = log_query_cost(response, operation: "orders")
        handle_query_errors(response, resource_name: "orders")

        page = extract_pagination(response.body["data"], resource_name: "orders")
        report_truncated_line_items(page[:items])

        page.merge(query_cost:)
      end

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

      def handle_query_errors(response, resource_name:)
        errors = response.body["errors"]
        return unless errors

        error_messages = errors.pluck("message").join(", ")
        raise ApiError, "Failed to fetch #{resource_name}: #{error_messages}"
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

      def log_query_cost(response, operation:)
        cost = response.body.dig("extensions", "cost")
        return if cost.blank?

        throttle = cost["throttleStatus"] || {}
        measured = {
          requested: cost["requestedQueryCost"],
          actual: cost["actualQueryCost"],
          available: throttle["currentlyAvailable"],
          maximum: throttle["maximumAvailable"],
          restore_rate: throttle["restoreRate"]
        }

        Rails.logger.info(
          "Shopify #{operation} query cost: requested=#{measured[:requested]} " \
          "actual=#{measured[:actual]} available=#{measured[:available]}/#{measured[:maximum]} " \
          "restore_rate=#{measured[:restore_rate]}"
        )

        measured
      end

      def report_truncated_line_items(orders)
        truncated_ids = Array(orders).filter_map do |order|
          order["id"] if order&.dig("lineItems", "pageInfo", "hasNextPage")
        end
        return if truncated_ids.empty?

        message = "Shopify line items truncated for #{truncated_ids.size} order(s): #{truncated_ids.join(", ")}"

        Rails.logger.error(message)
        Sentry.capture_message(
          message,
          level: :error,
          tags: {api: "shopify", operation: "lineItems"},
          extra: {order_ids: truncated_ids}
        )
      end

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

            updated_status = query_media_status(media_node["id"])
            media_node.merge!(updated_status) if updated_status
          end
        end
      end

      def query_media_status(media_id)
        query = Shopify::Graphql::MediaMutation.status_query

        response = graphql_client.query(query: query, variables: {id: media_id})
        response.body.dig("data", "node")
      end
    end
  end
end
