# == Schema Information
#
# Table name: payments
#
#  id           :bigint           not null, primary key
#  payment_date :datetime         not null
#  value        :decimal(8, 2)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  purchase_id  :bigint           not null
#
class Payment < ApplicationRecord
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
  db_belongs_to :purchase, touch: true

  #
  # == Scopes
  #
  # (none)

  #
  # == Class Methods
  #
  # (none)

  #
  # == Domain Methods
  #
  # (none)
end
