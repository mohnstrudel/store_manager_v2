class Shopify::PullSaleJob < ApplicationJob
  queue_as :default

  def perform(sale_id)
    return if sale_id.blank?

    api_client = Shopify::ApiClient.new
    response_body = api_client.pull_order(sale_id)

    if response_body["errors"].blank?
      sale_data = response_body["data"]["order"]
      parsed_sale = Shopify::SaleParser
        .new(api_sale: sale_data)
        .parse

      if parsed_sale
        Shopify::SaleCreator
          .new(parsed_sale: parsed_sale)
          .update_or_create!
      end
    end
  end
end
