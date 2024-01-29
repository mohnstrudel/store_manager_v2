# == Schema Information
#
# Table name: product_sales
#
#  id           :bigint           not null, primary key
#  full_title   :string
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

  after_create :calculate_title

  def item
    variation.presence || product
  end

  private

  def calculate_title
    self.full_title = variation_id.present? ?
      variation.title :
      product.full_title
    save
  end
end
