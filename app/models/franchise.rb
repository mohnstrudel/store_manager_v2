# frozen_string_literal: true
# == Schema Information
#
# Table name: franchises
#
#  id         :bigint           not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Franchise < ApplicationRecord
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
  has_associated_audits

  #
  # == Validations
  #
  validates :title, presence: true

  #
  # == Associations
  #
  has_many :products, dependent: :destroy

  #
  # == Callbacks
  #
  after_save :update_products

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

  private

  def update_products
    products.each(&:update_full_title)
  end
end
