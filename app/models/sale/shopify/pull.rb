# frozen_string_literal: true

class Sale::Shopify::Pull < Shopify::Pull
  private

  def fetch(api_client, cursor:, batch_size:, updated_since:)
    api_client.fetch_orders(cursor:, batch_size:, updated_since:)
  end

  def batch_size
    250
  end

  def importer_class
    Sale::Shopify::Importer
  end

  def parser_class
    Sale::Shopify::Parser
  end

  def skippable_errors
    [Sale::Shopify::Importer::Error, Customer::Shopify::Importer::Error]
  end
end
