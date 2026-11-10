# frozen_string_literal: true

module Shopify
  class PullSaleJob < Shopify::ApiJob
    include NotifiesRequester

    OrderNotFound = Class.new(StandardError)
    FetchRejected = Class.new(StandardError)

    discard_on(OrderNotFound) { |job, _error| job.send(:resolve_import_failure) }
    discard_on(FetchRejected, Sale::Shopify::Importer::Error, Customer::Shopify::Importer::Error) do |job, error|
      job.send(:record_import_failure, error)
    end

    def perform(sale_store_id, requested_by: nil)
      raise ArgumentError, "Sale store_id is required" if sale_store_id.blank?

      response = fetch_order(sale_store_id)
      sale = Sale::Shopify::Importer.import(Sale::Shopify::Parser.parse(response))

      sale.reconcile_installment_sale_items_later if sale.linked_to_payment_plan?
      notify_requester_of_success("#{job_title} finished.")
    end

    private

    def fetch_order(sale_store_id)
      Shopify::Api::Client.new.fetch_order(sale_store_id).presence || raise(OrderNotFound, "Shopify has no order #{sale_store_id}")
    rescue Shopify::Api::Client::Throttled
      raise
    rescue Shopify::Api::Client::ApiError => error
      raise FetchRejected, error.message
    end

    def job_title
      "Shopify order pull"
    end

    def resolve_import_failure
      Sale::ImportFailure.resolve(store_name: "shopify", store_order_id: arguments.first)
    end

    def record_import_failure(error)
      event = Sentry.capture_exception(error)

      Sale::ImportFailure.record_safely(
        store_name: "shopify",
        store_order_id: arguments.first,
        message: error.message,
        sentry_event_id: event&.event_id,
        failed_at: Time.current
      )
    end

    def failure_notification(error)
      if error.is_a?(OrderNotFound)
        {message: "This order was not found in Shopify."}
      else
        {message: "This order could not be pulled from Shopify.", link: broken_sales_link}
      end
    end
  end
end
