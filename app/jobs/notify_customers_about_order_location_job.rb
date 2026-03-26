# frozen_string_literal: true

class NotifyCustomersAboutOrderLocationJob < ApplicationJob
  queue_as :default

  def perform
    purchase_item_ids = PurchaseItem
      .includes(:sale_item)
      .where.not(sale_item: nil)
      .pluck(:id)
    PurchaseItem.notify_order_status!(purchase_item_ids:)
  end
end
