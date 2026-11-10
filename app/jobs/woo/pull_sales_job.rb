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

    discard_on(Woo::Api::Client::Error) { |job, error| job.send(:report, error) }
    retry_on(Woo::Api::Client::Unavailable, wait: :polynomially_longer, attempts: 5) do |job, error|
      job.send(:record_unreachable_order, error, job.send(:report, error))
    end

    def perform(limit: nil, pages: nil, id: nil, requested_by: nil)
      Sale::Woo::Pull.run(limit:, pages:, id:)
      notify_requester_of_success(id ? "WooCommerce order pull finished." : "WooCommerce sales pull finished.")
      nil
    end

    private

    def report(error)
      Sentry.capture_exception(error, extra: {status: error.status, url: error.url, body_preview: error.body_preview})
    end

    def record_unreachable_order(error, event)
      return if order_id.blank?

      Sale::ImportFailure.record_safely(
        store_name: "woo",
        store_order_id: order_id,
        message: error.message,
        sentry_event_id: event&.event_id,
        failed_at: Time.current
      )
    end

    def order_id
      options = arguments.last
      options[:id] if options.is_a?(Hash)
    end

    def failure_notification(error)
      case error
      when Sale::Woo::Pull::Failed
        {message: "Some WooCommerce orders could not be pulled.", link: broken_sales_link}
      when Woo::Api::Client::NotFound
        order_id.present? ? {message: "This order was not found in WooCommerce."} : unexpected_response_notification
      when Woo::Api::Client::Unavailable
        {message: "WooCommerce did not respond, so nothing was pulled. Try again in a few minutes.", link: jobs_dashboard_link}
      when Woo::Api::Client::Error
        unexpected_response_notification
      else
        {message: "The WooCommerce pull failed.", link: jobs_dashboard_link}
      end
    end

    def unexpected_response_notification
      {message: "WooCommerce returned an unexpected response, so nothing was pulled.", link: jobs_dashboard_link}
    end
  end
end
