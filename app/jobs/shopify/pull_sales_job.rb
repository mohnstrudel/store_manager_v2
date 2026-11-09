# frozen_string_literal: true

module Shopify
  class PullSalesJob < Shopify::BasePullJob
    discard_on(Shopify::Pull::Failed) do |_job, error|
      event = Sentry.capture_exception(error)

      error.failures.each do |failure|
        Sale::ImportFailure.record_safely(
          store_name: "shopify",
          store_order_id: failure.store_id,
          message: failure.message,
          sentry_event_id: event&.event_id,
          failed_at: failure.failed_at
        )
      end
    end

    private

    def last_sync_at
      Config.shopify_sales_sync_at
    end

    def pull_class
      Sale::Shopify::Pull
    end

    def stamp_sync(started_at)
      Config.update_shopify_sales_sync_time(started_at)
    end

    def handle_terminal_page(updated_since:)
      Seal::SyncPaymentPlansJob.perform_later
      retry_unresolved_failures if updated_since
    end

    def retry_unresolved_failures
      Sale::ImportFailure.shopify.unresolved.find_each(&:pull_later)
    end
  end
end
