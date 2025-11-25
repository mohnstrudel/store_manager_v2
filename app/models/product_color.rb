# == Schema Information
#
# Table name: product_colors
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  color_id   :bigint
#  product_id :bigint
#
class ProductColor < ApplicationRecord
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
  # (none)

  #
  # == Associations
  #
  db_belongs_to :product
  db_belongs_to :color
  has_many :store_infos, as: :storable, dependent: :destroy

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
