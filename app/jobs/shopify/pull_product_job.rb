# frozen_string_literal: true
class Shopify::PullProductJob < ApplicationJob
  queue_as :default

  def perform(product_id)
    raise ArgumentError, "Shopify product ID is required" if product_id.blank?

    api_client = Shopify::ApiClient.new
    response = api_client.pull_product(product_id)

    parsed_product = Shopify::ProductParser
      .new(api_item: response)
      .parse

    Shopify::ProductCreator
      .new(parsed_item: parsed_product)
      .update_or_create!
  end
end
