# frozen_string_literal: true

# == Schema Information
#
# Table name: colors
#
#  id         :bigint           not null, primary key
#  value      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Color < ApplicationRecord
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
  has_many :product_colors, dependent: :destroy, inverse_of: :color
  has_many :products, through: :product_colors
  has_many :editions, dependent: :destroy, inverse_of: :color

  #
  # == Scopes
  #
  scope :includes_show_associations, -> { includes(:products) }

  #
  # == Class Methods
  #
  # (none)

  #
  # == Domain Methods
  #
  # (none)
end
