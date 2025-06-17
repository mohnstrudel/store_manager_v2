class NotifyCustomersAboutOrderLocationJob < ApplicationJob
  queue_as :default

  def perform
    purchase_item_ids = PurchaseItem
      .includes(:sale_item)
      .where.not(sale_item: nil)
      .pluck(:id)
    PurchasedNotifier.new(purchase_item_ids:).handle_product_purchase
  end
end
