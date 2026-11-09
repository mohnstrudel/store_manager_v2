# frozen_string_literal: true

module Shopify
  class PullSaleJob < Shopify::ApiJob
    discard_on(Sale::Shopify::Importer::Error) do |job, error|
      event = Sentry.capture_exception(error)

      Sale::ImportFailure.record_safely(
        store_name: "shopify",
        store_order_id: job.arguments.first,
        message: error.message,
        sentry_event_id: event&.event_id,
        failed_at: Time.current
      )
    end

    def perform(sale_store_id)
      raise ArgumentError, "Sale store_id is required" if sale_store_id.blank?

      response = Shopify::Api::Client.new.fetch_order(sale_store_id)
      sale = Sale::Shopify::Importer.import(Sale::Shopify::Parser.parse(response))

      sale.reconcile_installment_sale_items_later if sale.linked_to_payment_plan?
    end
  end
end
