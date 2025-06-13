class NotifyCustomersAboutOrderLocationJob < ApplicationJob
  queue_as :default

  def perform
    purchased_product_ids = PurchasedProduct
      .includes(:product_sale)
      .where.not(product_sale: nil)
      .pluck(:id)
    PurchasedNotifier.new(purchased_product_ids:).handle_product_purchase
  end
end
