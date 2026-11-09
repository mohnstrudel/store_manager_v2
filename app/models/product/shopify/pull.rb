# frozen_string_literal: true

class Product::Shopify::Pull < Shopify::Pull
  private

  def fetch(api_client, cursor:, batch_size:, updated_since:)
    api_client.fetch_products(cursor:, batch_size:, updated_since:)
  end

  def batch_size
    250
  end

  def importer_class
    Product::Shopify::Importer
  end

  def parser_class
    Product::Shopify::Parser
  end

  def skippable_errors
    [Product::Shopify::Importer::Error]
  end
end
