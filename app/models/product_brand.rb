# frozen_string_literal: true

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
  include HasAuditNotifications
  include ProductTitling

  audited

  db_belongs_to :product, inverse_of: :product_brands
  db_belongs_to :brand, inverse_of: :product_brands
end
