# == Schema Information
#
# Table name: product_brands
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  brand_id   :bigint
#  product_id :bigint
#
class ProductBrand < ApplicationRecord
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
  db_belongs_to :brand

  #
  # == Callbacks
  #
  after_save ->(product_brand) { product_brand.product.update_full_title }

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
