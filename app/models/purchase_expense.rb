# frozen_string_literal: true

# == Schema Information
#
# Table name: purchase_expenses
#
#  id               :bigint           not null, primary key
#  amount           :decimal(8, 2)    not null
#  description      :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  purchase_item_id :bigint           not null
#
class PurchaseExpense < ApplicationRecord
  include HasAuditNotifications

  audited associated_with: :purchase

  db_belongs_to :purchase_item, inverse_of: :purchase_expenses
  has_one :purchase, through: :purchase_item

  validates :description, presence: true
  validates :amount, presence: true, numericality: {greater_than_or_equal_to: 0}
  validate :purchase_item_cannot_change, on: :update

  after_commit :recalculate_purchase_item_expenses

  scope :for_display, -> { order(created_at: :asc, id: :asc) }

  private

  def purchase_item_cannot_change
    return unless will_save_change_to_purchase_item_id?

    errors.add(:purchase_item, "cannot be changed")
  end

  def recalculate_purchase_item_expenses
    return if purchase_item.destroyed?

    purchase_item.recalculate_expenses!
  end
end
