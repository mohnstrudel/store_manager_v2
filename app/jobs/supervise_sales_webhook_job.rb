class SuperviseSalesWebhookJob < ApplicationJob
  queue_as :default

  include Gettable

  def perform
    return if Config.sales_hook_disabled?

    latest_order = api_get_latest_orders.find do |order|
      order[:status].in? Sale.active_status_names
    end
    woo_id = latest_order[:id]

    if Sale.find_by(woo_id:).blank?
      Config.disable_sales_hook
    end
  end
end
