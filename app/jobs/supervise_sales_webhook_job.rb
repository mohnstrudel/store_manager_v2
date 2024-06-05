class SuperviseSalesWebhookJob < ApplicationJob
  queue_as :default

  include Gettable

  URL = "https://store.handsomecake.com/wp-json/wc/v3/orders/"

  def perform
    return if Config.sales_hook_disabled?

    order = api_get_latest(URL)
    woo_id = order[:id]

    if Sale.find_by(woo_id:).blank?
      Config.disable_sales_hook
    end
  end
end
