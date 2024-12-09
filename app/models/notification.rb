# == Schema Information
#
# Table name: notifications
#
#  id         :bigint           not null, primary key
#  event_type :integer          default("product_purchased"), not null
#  name       :string           not null
#  status     :integer          default("disabled"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Notification < ApplicationRecord
  enum :status, {
    disabled: 0,
    active: 1
  }, default: :disabled

  enum :event_type, {
    product_purchased: 0,
    warehouse_changed: 1
  }, default: :product_purchased

  has_many :warehouse_transitions, dependent: :nullify

  class << self
    def dispatch(event:, context: {})
      case event
      when event_types[:product_purchased]
        handle_product_purchased(context)
      when event_types[:warehouse_changed]
        handle_warehouse_changed(context)
      end
    end

    private

    def format_warehouse_name(warehouse)
      warehouse.external_name.presence || warehouse.name
    end

    def extract_common_data(purchased_product)
      return {} if purchased_product.sale.blank?

      {
        email: purchased_product.sale.customer.email,
        customer_name: purchased_product.sale.customer.full_name,
        order_number: purchased_product.sale.woo_id,
        item_name: purchased_product.product_sale.title
      }
    end

    def handle_product_purchased(context)
      purchased_product = PurchasedProduct
        .with_notification_details
        .includes(:warehouse)
        .find_by(id: context[:purchased_product_id])

      return if purchased_product&.sale.blank?

      data = extract_common_data(purchased_product)
      return if data[:email].blank?

      NotificationsMailer.product_purchased_email(
        **data,
        warehouse_name: format_warehouse_name(purchased_product.warehouse)
      ).deliver_later
    end

    def handle_warehouse_changed(context)
      purchased_product_ids = Array(
        context[:purchased_product_ids] ||
        context[:purchased_product_id]
      )

      purchased_products = PurchasedProduct
        .with_notification_details
        .where(id: purchased_product_ids)

      transition = WarehouseTransition
        .includes(:notification, :from_warehouse, :to_warehouse)
        .find_by(
          from_warehouse_id: context[:from_id],
          to_warehouse_id: context[:to_id]
        )

      return unless transition&.notification&.active?

      purchased_products.each do |purchased_product|
        data = extract_common_data(purchased_product)
        next if data[:email].blank?

        NotificationsMailer.warehouse_changed_email(
          **data,
          from_warehouse: format_warehouse_name(transition.from_warehouse),
          to_warehouse: format_warehouse_name(transition.to_warehouse),
          tracking_number: purchased_product.tracking_number,
          tracking_url: purchased_product&.shipping_company&.tracking_url
        ).deliver_later
      end
    end
  end
end
