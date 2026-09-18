# frozen_string_literal: true

module Shopify
  module Graphql
    class OrderQuery
      SALE_PRODUCT_FIELDS = <<~GQL
        id
      GQL

      SALE_FIELDS = <<~GQL
        cancelledAt
        cancelReason
        closed
        closedAt
        confirmed
        createdAt
        currencyCode
        displayFinancialStatus
        displayFulfillmentStatus
        fullyPaid
        id
        name
        note
        presentmentCurrencyCode
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
        currentTotalPriceSet {
          shopMoney {
            amount
          }
        }
        totalReceivedSet {
          shopMoney {
            amount
          }
        }
        totalOutstandingSet {
          shopMoney {
            amount
          }
        }
        netPaymentSet {
          shopMoney {
            amount
          }
        }
        totalRefundedSet {
          shopMoney {
            amount
          }
        }
        paymentGatewayNames
        paymentTerms {
          id
          paymentTermsName
          paymentTermsType
          overdue
          paymentSchedules(first: 250) {
            nodes {
              id
              balanceDue {
                amount
              }
              totalBalance {
                amount
              }
              completedAt
              due
              dueAt
              issuedAt
            }
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
          firstName
          lastName
          address1
          address2
          city
          company
          country
          province
          provinceCode
          zip
          phone
        }
        billingAddress {
          firstName
          lastName
          address1
          address2
          city
          company
          country
          province
          provinceCode
          zip
          phone
        }
        lineItems(first: 10) {
          pageInfo {
            hasNextPage
          }
          nodes {
            id
            quantity
            originalTotalSet {
              shopMoney {
                amount
              }
            }
            discountedTotalSet {
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

      def self.by_id
        <<~GQL
          query($id: ID!) {
            order(id: $id) {
              #{SALE_FIELDS}
            }
          }
        GQL
      end

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
