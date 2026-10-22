# frozen_string_literal: true

module PurchaseItem::Shipping
  extend ActiveSupport::Concern

  included do
    before_save :stamp_shipped_at, if: :stamp_shipped_at?
    after_commit :update_purchase_shipping_total, if: :should_update_purchase_shipping?
  end

  def shipped_at=(value) # rubocop:disable Project/PrivateMethodCandidate
    parsed = value&.in_time_zone
    super((parsed&.to_date == shipped_at&.to_date) ? shipped_at : parsed)
  end

  private

  def stamp_shipped_at?
    will_save_change_to_tracking_number? && !will_save_change_to_shipped_at?
  end

  def stamp_shipped_at
    self.shipped_at = tracking_number.present? ? Time.current : nil
  end

  def should_update_purchase_shipping?
    previously_new_record? || destroyed? || saved_change_to_shipping_cost? || saved_change_to_purchase_id?
  end

  def update_purchase_shipping_total
    if previously_new_record?
      adjust_purchase_shipping_total(purchase, shipping_cost)
    elsif destroyed?
      adjust_purchase_shipping_total(purchase, -shipping_cost)
    elsif saved_change_to_purchase_id?
      old_purchase_id, = saved_change_to_purchase_id
      old_shipping_cost = saved_change_to_shipping_cost? ? saved_change_to_shipping_cost.first : shipping_cost
      adjust_purchase_shipping_total(Purchase.find_by(id: old_purchase_id), -old_shipping_cost)
      adjust_purchase_shipping_total(purchase, shipping_cost)
    else
      delta = saved_change_to_shipping_cost.last - saved_change_to_shipping_cost.first
      adjust_purchase_shipping_total(purchase, delta)
    end
  end

  def adjust_purchase_shipping_total(target_purchase, delta)
    return if target_purchase.nil? || target_purchase.destroyed? || delta.nil? || delta.zero?

    target_purchase.with_lock do
      target_purchase.update_column(:shipping_total, target_purchase.shipping_total + delta)
    end
  end
end
