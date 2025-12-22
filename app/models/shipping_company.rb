# frozen_string_literal: true
# == Schema Information
#
# Table name: shipping_companies
#
#  id           :bigint           not null, primary key
#  name         :string
#  tracking_url :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class ShippingCompany < ApplicationRecord
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
  audited

  #
  # == Validations
  #
  validates_db_uniqueness_of :name
  validates :tracking_url, presence: true

  #
  # == Associations
  #
  has_many :purchase_items, dependent: :nullify

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
