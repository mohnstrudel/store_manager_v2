# frozen_string_literal: true

module Product::InitialPurchase
  extend ActiveSupport::Concern

  def apply_initial_purchase!(attributes)
    return if attributes.blank?

    purchase = purchases.last
    return unless purchase

    purchase.move_to_warehouse!(attributes[:warehouse_id]) if attributes[:warehouse_id].present?

    sync_initial_payment!(purchase, attributes[:payment_value])
  end

  private

  def sync_initial_payment!(purchase, payment_value)
    return if payment_value.blank?

    payment = purchase.payments.order(:id).first_or_initialize
    payment.value = payment_value
    payment.save! if payment.new_record? || payment.changed?
  end
end
