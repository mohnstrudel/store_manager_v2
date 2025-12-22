# frozen_string_literal: true
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
  # Touch is enabled so the purchase is updated when we pay
  # Counter cache is enabled to track unpaid purchases
  db_belongs_to :purchase, touch: true, counter_cache: true

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
