# == Schema Information
#
# Table name: product_sizes
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  product_id :bigint
#  size_id    :bigint
#
class ProductSize < ApplicationRecord
  belongs_to :product
  belongs_to :size
end
