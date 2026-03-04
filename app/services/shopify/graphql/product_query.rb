# frozen_string_literal: true

# Shopify::Graphql::ProductQuery
#
# GraphQL queries for fetching products from Shopify.
# Provides queries for both individual products and paginated product lists.
#
module Shopify
  module Graphql
    class ProductQuery
      # GraphQL fields for a product including media and variants
      PRODUCT_FIELDS = <<~GQL
        id
        title
        handle
        descriptionHtml
        tags
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
              sku
              price
              inventoryItem {
                id
                unitCost {
                  amount
                  currencyCode
                }
                measurement {
                  weight {
                    value
                  }
                }
              }
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

      # Query for fetching a single product by ID
      #
      # @return [String] The GraphQL query string
      def self.by_id
        <<~GQL
          query ProductById($id: ID!) {
            product(id: $id) {
              #{PRODUCT_FIELDS}
            }
          }
        GQL
      end

      # Query for fetching paginated list of products
      #
      # @return [String] The GraphQL query string
      def self.list
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
    end
  end
end
