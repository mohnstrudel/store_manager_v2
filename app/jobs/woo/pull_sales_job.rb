# frozen_string_literal: true

module Woo
  class PullSalesJob < ApplicationJob
    queue_as :default
    discard_on(Sale::Woo::Pull::Failed) do |_job, error|
      Sentry.capture_exception(error, extra: {failed_woo_order_ids: error.failures.map(&:woo_id)})
    end

    def perform(limit: nil, pages: nil, id: nil)
      Sale::Woo::Pull.run(limit:, pages:, id:)
      nil
    end
  end
end
