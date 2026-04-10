# frozen_string_literal: true

# Shopify::Graphql::OrderQuery
#
# GraphQL queries for fetching orders from Shopify.
# Provides queries for both individual orders and paginated order lists.
#
module Shopify
  module Graphql
    class OrderQuery
      SALE_PRODUCT_FIELDS = <<~GQL
        id
      GQL

      # GraphQL fields for an order including customer and line items
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
        totalDiscountsSet {
          shopMoney {
            amount
          }
        }
        totalPriceSet {
          shopMoney {
            amount
          }
        }
        totalShippingPriceSet {
          shopMoney {
            amount
          }
        }
        unpaid
        updatedAt
        phone
        email
        customer {
          id
          lastName
          firstName
          defaultEmailAddress {
            emailAddress
          }
          defaultPhoneNumber {
            phoneNumber
          }
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
            originalTotalSet {
              shopMoney {
                amount
              }
            }
            variantTitle
            title
            variant {
              id
              product {
                id
              }
            }
            product {
              #{SALE_PRODUCT_FIELDS}
            }
          }
        }
      GQL

      # Query for fetching a single order by ID
      #
      # @return [String] The GraphQL query string
      def self.by_id
        <<~GQL
          query($id: ID!) {
            order(id: $id) {
              #{SALE_FIELDS}
            }
          }
        GQL
      end

      # Query for fetching paginated list of orders
      #
      # @return [String] The GraphQL query string
      def self.list
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
  end
end
