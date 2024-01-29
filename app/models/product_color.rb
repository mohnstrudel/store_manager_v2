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
  after_save ->(product_color) { product_color.product.set_full_title }

  db_belongs_to :product
  db_belongs_to :color
end
