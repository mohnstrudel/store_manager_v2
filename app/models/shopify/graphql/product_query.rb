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

      def self.by_id
        <<~GQL
          query ProductById($id: ID!) {
            product(id: $id) {
              #{PRODUCT_FIELDS}
            }
          }
        GQL
      end

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
