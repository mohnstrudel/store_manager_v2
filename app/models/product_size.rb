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
  after_save ->(product_size) { product_size.product.set_full_title }

  db_belongs_to :product
  db_belongs_to :size
end
