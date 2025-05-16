class Shopify::PullProductJob < ApplicationJob
  queue_as :default

  def perform(product_id)
    return if product_id.blank?

    api_client = Shopify::ApiClient.new
    response_body = api_client.pull_product(product_id)

    if response_body["errors"].blank?
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
end
