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
  db_belongs_to :product
  db_belongs_to :brand
end
