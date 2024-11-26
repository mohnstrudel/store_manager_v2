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

  def self.dispatch(event:, context: {})
    case event
    when event_types[:product_purchased]
      purchased_product = PurchasedProduct
        .includes(
          :warehouse,
          sale: :customer,
          product_sale: [
            :product,
            variation: [:size, :version, :color]
          ]
        )
        .where(id: context[:purchased_product_id])
        .first

      return if purchased_product.sale.blank?

      email = purchased_product.sale.customer.email
      customer_name = purchased_product.sale.customer.full_name
      order_number = purchased_product.sale.woo_id
      item_name = purchased_product.product_sale.title
      warehouse_name = purchased_product.warehouse.external_name.presence ||
        purchased_product.warehouse.name

      return if email.blank?

      NotificationsMailer.product_purchased_email(
        customer_name:,
        email:,
        item_name:,
        order_number:,
        warehouse_name:
      ).deliver_later

    when event_types[:warehouse_changed]
      purchased_product_ids = context[:purchased_product_ids] ||
        [context[:purchased_product_id]]

      purchased_products = PurchasedProduct
        .includes(
          sale: [:customer],
          product_sale: [
            :product,
            variation: [:size, :version, :color]
          ]
        )
        .where(id: purchased_product_ids)

      transition = WarehouseTransition
        .includes(:notification, :from_warehouse, :to_warehouse)
        .find_by(
          from_warehouse_id: context[:from_id],
          to_warehouse_id: context[:to_id]
        )

      if transition&.notification&.active?
        purchased_products.each do |purchased_product|
          next if purchased_product.sale.blank?

          email = purchased_product.sale.customer.email
          customer_name = purchased_product.sale.customer.full_name
          order_number = purchased_product.sale.woo_id
          item_name = purchased_product.product_sale.title
          from_warehouse = transition.from_warehouse.external_name.presence ||
            transition.from_warehouse.name
          to_warehouse = transition.to_warehouse.external_name.presence ||
            transition.to_warehouse.name

          next if email.blank?

          NotificationsMailer.warehouse_changed_email(
            customer_name:,
            email:,
            from_warehouse:,
            item_name:,
            order_number:,
            to_warehouse:
          ).deliver_later
        end
      end
    end
  end
end
