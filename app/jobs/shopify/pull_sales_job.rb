# frozen_string_literal: true

module Shopify
  class PullSalesJob < Shopify::BasePullJob
    private

    def process_item(api_item)
      super
    rescue Sale::Shopify::Importer::Error => e
      Rails.logger.error("Skipping Shopify order due to import failure: #{e.message}")
    end

    def fetch_from_api(api_client, cursor:, batch_size:)
      api_client.fetch_orders(cursor: cursor, batch_size: batch_size)
    end

    def parser_class
      Sale::Shopify::Parser
    end

    def creator_class
      Sale::Shopify::Importer
    end

    def batch_size
      250
    end

    def handle_terminal_page
      Seal::SyncPaymentPlansJob.perform_later
    end
  end
end
