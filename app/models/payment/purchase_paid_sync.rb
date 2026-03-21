# frozen_string_literal: true

module Payment::PurchasePaidSync
  extend ActiveSupport::Concern

  included do
    after_commit :update_purchase_paid_count, if: :should_update_paid?
  end

  private

  def should_update_paid?
    previously_new_record? || destroyed? || saved_change_to_value?
  end

  def update_purchase_paid_count
    delta =
      if previously_new_record?
        value
      elsif destroyed?
        -value
      else
        saved_change_to_value.last - saved_change_to_value.first
      end

    return if delta.zero?

    purchase.with_lock do
      purchase.paid += delta
      purchase.save!
    end
  end
end
