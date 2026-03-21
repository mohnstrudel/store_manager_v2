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
  include HasAuditNotifications

  audited

  validates_db_uniqueness_of :name
  validates :tracking_url, presence: true

  has_many :purchase_items, dependent: :nullify, inverse_of: :shipping_company

  scope :ordered, -> { order(:name) }
end
