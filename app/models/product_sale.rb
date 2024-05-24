# == Schema Information
#
# Table name: product_sales
#
#  id           :bigint           not null, primary key
#  price        :decimal(8, 2)
#  qty          :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  product_id   :bigint           not null
#  sale_id      :bigint           not null
#  variation_id :bigint
#  woo_id       :string
#
class ProductSale < ApplicationRecord
  db_belongs_to :product
  db_belongs_to :sale
  belongs_to :variation, optional: true

  def item
    variation.presence || product
  end

  def title
    variation_id.present? ?
      "#{product.full_title} → #{variation.title}" :
      product.full_title
  end
end
