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

  delegate :status, to: :sale

  def item
    (variation.presence || product)
  end

  def item_title
    item.methods.include?(:full_title) ? item.full_title : item.title
  end

  def purchase_debt
    wip_product_sales_size = item
      .product_sales
      .includes(:sale)
      .where(sale: {status: Sale.wip_statuses})
      .size
    wip_product_sales_size - item.purchases.size
  end
end
