class Shopify::PullSalesJob < Shopify::BasePullJob
  private

  def resource_name
    "orders"
  end

  def parser_class
    Shopify::SaleParser
  end

  def creator_class
    Shopify::SaleCreator
  end

  def batch_size
    250
  end

  def query
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
              totalDiscounts
              totalPrice
              totalShippingPrice
              unpaid
              updatedAt
              phone
              email
              customer {
                id
                lastName
                email
                firstName
                phone
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
                  originalTotal
                  variantTitle
                  title
                  variant {
                    id
                    displayName
                    product {
                      id
                    }
                  }
                  product {
                    id
                    title
                    handle
                    images(first: 10) {
                      edges {
                        node {
                          src
                        }
                      }
                    }
                    variants(first: 10) {
                      edges {
                        node {
                          id
                          title
                          selectedOptions {
                            value
                            name
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    GQL
  end
end
