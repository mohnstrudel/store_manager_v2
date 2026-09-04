# frozen_string_literal: true

module Shopify
  module Graphql
    class BaseQuery
      def self.execute_query(client, query, variables: {})
        response = client.query(query:, variables:)
        response.body
      end

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
