# frozen_string_literal: true

# == Schema Information
#
# Table name: payments
#
#  id           :bigint           not null, primary key
#  payment_date :datetime         not null
#  value        :decimal(8, 2)    default(0.0)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  purchase_id  :bigint           not null
#
class Payment < ApplicationRecord
  after_commit :update_purchase_paid_count, if: :should_update_paid?

  #
  # == Concerns
  #
  include HasAuditNotifications

  #
  # == Extensions
  #
  # (none)

  #
  # == Configuration
  #
  audited associated_with: :purchase

  #
  # == Validations
  #
  validates :value, presence: true

  #
  # == Associations
  #
  # Touch is enabled so the purchase is updated when we pay
  # Counter cache is enabled to track unpaid purchases
  db_belongs_to :purchase, touch: true, counter_cache: true, inverse_of: :payments

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
