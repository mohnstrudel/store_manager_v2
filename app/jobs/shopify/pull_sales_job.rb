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

    def pull_class
      Sale::Shopify::Pull
    end

    def handle_terminal_page
      Seal::SyncPaymentPlansJob.perform_later
    end
  end
end
