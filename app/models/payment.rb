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
  include HasAuditNotifications
  include PurchasePaidSync

  audited associated_with: :purchase

  validates :value, presence: true

  scope :chronological, -> { order(payment_date: :asc, created_at: :asc) }

  db_belongs_to :purchase, touch: true, counter_cache: true, inverse_of: :payments
end
