class Shopify::PullProductJob < ApplicationJob
  queue_as :default

  def perform(product_id)
    return if product_id.blank?

    api_client = Shopify::ApiClient.new
    response_body = api_client.query(
      query: query,
      variables: {id: product_id}
    ).body

    if response_body["errors"].blank? && response_body["data"]["product"].present?
      product_data = response_body["data"]["product"]
      parsed_product = Shopify::ProductParser
        .new(api_product: product_data)
        .parse

      if parsed_product
        Shopify::ProductCreator
          .new(parsed_product: parsed_product)
          .update_or_create!
      end
    end
  end

  private

  def query
    <<~GQL
      query($id: ID!) {
        product(id: $id) {
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
    GQL
  end
end
