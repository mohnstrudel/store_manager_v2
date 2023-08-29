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
  belongs_to :product
  belongs_to :color
end
