class Shopify::PullSaleJob < ApplicationJob
  queue_as :default

  def perform(sale_id)
    raise ArgumentError, "Shopify order ID is required" if sale_id.blank?

    api_client = Shopify::ApiClient.new
    response = api_client.pull_order(sale_id)

    parsed_sale = Shopify::SaleParser
      .new(api_item: response)
      .parse

    Shopify::SaleCreator
      .new(parsed_item: parsed_sale)
      .update_or_create!
  end
end
