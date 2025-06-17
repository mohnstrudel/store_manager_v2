# == Schema Information
#
# Table name: suppliers
#
#  id         :bigint           not null, primary key
#  slug       :string
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Supplier < ApplicationRecord
  #
  # == Concerns
  #
  include HasAuditNotifications

  #
  # == Extensions
  #
  extend FriendlyId

  #
  # == Configuration
  #
  audited
  has_associated_audits
  friendly_id :title, use: :slugged

  #
  # == Validations
  #
  validates :title, presence: true

  #
  # == Associations
  #
  has_many :product_suppliers, dependent: :destroy
  has_many :products, through: :product_suppliers
  has_many :purchases, dependent: :destroy

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
