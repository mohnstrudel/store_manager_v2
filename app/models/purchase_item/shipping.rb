# frozen_string_literal: true

module PurchaseItem::Shipping
  extend ActiveSupport::Concern

  included do
    after_commit :update_purchase_shipping_total, if: :should_update_purchase_shipping?
  end

  private

  def should_update_purchase_shipping?
    previously_new_record? || destroyed? || saved_change_to_shipping_cost?
  end

  def update_purchase_shipping_total
    delta =
      if previously_new_record?
        shipping_cost
      elsif destroyed?
        -shipping_cost
      else
        saved_change_to_shipping_cost.last - saved_change_to_shipping_cost.first
      end

    return if delta.zero?

    purchase.with_lock do
      purchase.shipping_total += delta
      purchase.save!
    end
  end
end
