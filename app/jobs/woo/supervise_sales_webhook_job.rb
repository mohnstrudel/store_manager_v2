# frozen_string_literal: true

module Woo
  class SuperviseSalesWebhookJob < ApplicationJob
    queue_as :default

    def perform
      return if Config.sales_hook_disabled?

      latest_orders = Woo::Api::Client.new.fetch_latest_orders

      unless latest_orders
        report_missing_latest_orders
        return
      end

      latest_order = latest_orders.find do |order|
        order[:status].in? Sale::ACTIVE_STATUSES
      end

      unless latest_order
        report_missing_active_order(latest_orders)
        return
      end

      woo_id = latest_order[:id]

      if Sale.find_by_woo_id(woo_id).blank?
        Rails.logger.warn("[Woo::SuperviseSalesWebhookJob] Disabling sales hook because Woo order #{woo_id} is missing locally")
        Config.disable_sales_hook
      end
    end

    private

    def report_missing_latest_orders
      Rails.logger.error("[Woo::SuperviseSalesWebhookJob] Latest Woo orders were unavailable")
      Sentry.capture_message(
        "Woo supervise sales webhook could not load latest orders",
        level: :error,
        tags: {
          job: self.class.name,
          integration: "woo"
        }
      )
    end

    def report_missing_active_order(latest_orders)
      statuses = latest_orders.filter_map { |order| order[:status] }.uniq

      Rails.logger.warn("[Woo::SuperviseSalesWebhookJob] No active Woo order found in latest orders")
      Sentry.capture_message(
        "Woo supervise sales webhook found no active orders",
        level: :warning,
        tags: {
          job: self.class.name,
          integration: "woo"
        },
        extra: {
          active_status_names: Sale::ACTIVE_STATUSES,
          returned_statuses: statuses,
          orders_checked: latest_orders.size
        }
      )
    end
  end
end
