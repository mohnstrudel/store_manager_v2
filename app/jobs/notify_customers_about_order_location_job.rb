# frozen_string_literal: true
class NotifyCustomersAboutOrderLocationJob < ApplicationJob
  queue_as :default

  def perform
    purchase_item_ids = PurchaseItem
      .includes(:sale_item)
      .where.not(sale_item: nil)
      .pluck(:id)
    PurchasedNotifier.handle_product_purchase(purchase_item_ids:)
  end
end
