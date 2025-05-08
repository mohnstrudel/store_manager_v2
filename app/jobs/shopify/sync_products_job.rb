class Shopify::SyncProductsJob < Shopify::BaseSyncJob
  private

  def resource_name
    "products"
  end

  def parser_class
    Shopify::ProductParser
  end

  def creator_class
    Shopify::ProductCreator
  end

  def batch_size
    250
  end

  def query
    <<~GQL
      query($first: Int!, $after: String) {
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
    GQL
  end
end
