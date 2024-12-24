class NotifyCustomersAboutOrderLocationJob < ApplicationJob
  queue_as :default

  def perform
    PurchasedProduct
      .includes(:product_sale)
      .where.not(product_sale: nil)
      .find_each do |purchased_product|
        Notifier.new(
          purchased_product_id: purchased_product.id
        ).handle_product_purchase
      end
  end
end
