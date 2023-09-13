# == Schema Information
#
# Table name: product_sales
#
#  id         :bigint           not null, primary key
#  price      :decimal(8, 2)
#  qty        :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  product_id :bigint           not null
#  sale_id    :bigint           not null
#
class ProductSale < ApplicationRecord
  belongs_to :product
  belongs_to :sale
end
