# frozen_string_literal: true

module Product::InitialPurchase
  extend ActiveSupport::Concern

  def apply_initial_purchase!(attributes)
    return if attributes.blank?

    purchase_attributes = attributes.except(:warehouse_id, :payment_value)
    purchase = purchases.create!(purchase_attributes)

    purchase.move_to_warehouse!(attributes[:warehouse_id]) if attributes[:warehouse_id].present?

    create_initial_payment!(purchase, attributes[:payment_value])
  end

  private

  def create_initial_payment!(purchase, payment_value)
    return if payment_value.blank?

    purchase.payments.create!(value: payment_value)
  end
end
