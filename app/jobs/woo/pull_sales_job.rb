# frozen_string_literal: true

module Woo
  class PullSalesJob < ApplicationJob
    include NotifiesRequester

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

    def perform(limit: nil, pages: nil, id: nil, requested_by: nil)
      Sale::Woo::Pull.run(limit:, pages:, id:)
      notify_requester_of_success(id ? "WooCommerce order pull finished." : "WooCommerce sales pull finished.")
      nil
    end

    private

    def failure_notification(_error)
      {message: "Some WooCommerce orders could not be pulled.", link: broken_sales_link}
    end
  end
end
