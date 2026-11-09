# frozen_string_literal: true

module Woo
  class PullSalesJob < ApplicationJob
    queue_as :default
    discard_on(Sale::Woo::Pull::Failed) do |_job, error|
      event = Sentry.capture_exception(error, extra: {failed_woo_order_ids: error.failures.map(&:woo_id)})

      error.failures.each do |failure|
        Sale::ImportFailure.record_safely(
          store_name: "woo",
          store_order_id: failure.woo_id,
          message: failure.message,
          sentry_event_id: event&.event_id,
          failed_at: failure.failed_at
        )
      end
    end

    def perform(limit: nil, pages: nil, id: nil)
      Sale::Woo::Pull.run(limit:, pages:, id:)
      nil
    end
  end
end
