# == Schema Information
#
# Table name: versions
#
#  id         :bigint           not null, primary key
#  value      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Version < ApplicationRecord
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
  validates :value, presence: true

  #
  # == Associations
  #
  has_many :product_versions, dependent: :destroy
  has_many :products, through: :product_versions
  has_many :editions, dependent: :destroy

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
