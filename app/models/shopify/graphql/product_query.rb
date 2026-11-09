# frozen_string_literal: true

module Shopify
  module Graphql
    class ProductQuery
      PRODUCT_FIELDS = <<~GQL
        id
        title
        handle
        descriptionHtml
        tags
        createdAt
        updatedAt
        publishedAt
        media(first: 250) {
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
      GQL

      VARIANT_CONNECTION_FIELDS = <<~GQL
        pageInfo {
          hasNextPage
        }
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
      GQL

      def self.by_id
        <<~GQL
          query ProductById($id: ID!) {
            product(id: $id) {
              #{PRODUCT_FIELDS}
              variants(first: 250) {
                #{VARIANT_CONNECTION_FIELDS}
              }
            }
          }
        GQL
      end

      def self.list(updated_since: nil)
        <<~GQL
          query FetchProducts($first: Int!, $after: String) {
            products(
              first: $first,
              after: $after,
              #{Shopify::Graphql::ListArguments.for(updated_since:)}
            ) {
              pageInfo {
                hasNextPage
                endCursor
              }
              edges {
                node {
                  #{PRODUCT_FIELDS}
                  variants(first: 100) {
                    #{VARIANT_CONNECTION_FIELDS}
                  }
                }
              }
            }
          }
        GQL
      end
    end
  end
end
