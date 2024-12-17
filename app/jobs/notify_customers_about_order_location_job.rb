class NotifyCustomersAboutOrderLocationJob < ApplicationJob
  queue_as :default

  def perform
    PurchasedProduct
      .includes(:product_sale)
      .where.not(product_sale: nil)
      .find_each do |purchased_product|
        Notification.dispatch(
          event: Notification.event_types[:product_purchased],
          context: {purchased_product_id: purchased_product.id}
        )
      end
  end
end
