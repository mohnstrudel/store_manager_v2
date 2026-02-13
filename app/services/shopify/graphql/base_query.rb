# frozen_string_literal: true

# Shopify::Graphql::BaseQuery
#
# Base class for Shopify GraphQL operations.
# Provides shared error handling and execution logic for all GraphQL queries and mutations.
#
module Shopify
  module Graphql
    class BaseQuery
      # Executes a GraphQL query and returns the response body
      #
      # @param client [ShopifyAPI::Clients::Graphql::Admin] The GraphQL client
      # @param query [String] The GraphQL query string
      # @param variables [Hash] Variables for the query
      # @return [Hash] The response body
      def self.execute_query(client, query, variables: {})
        response = client.query(query:, variables:)
        response.body
      end

      # Handles errors from Shopify GraphQL mutations
      #
      # @param query [String] The GraphQL query string (for logging)
      # @param response [Object] The response object
      # @param operation_name [String] Name of the operation (e.g., "productCreate")
      # @raise [Shopify::Api::Client::ApiError] If errors are present in the response
      def self.handle_mutation_errors(query, response, operation_name)
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

          raise Shopify::Api::Client::ApiError, "Failed to call the #{operation_name} API mutation: #{error_messages}"
        end
      end
    end
  end
end
