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
  after_create :link_purchased_products

  validates_db_uniqueness_of :woo_id

  db_belongs_to :product
  db_belongs_to :sale

  belongs_to :variation, optional: true

  has_many :purchased_products, dependent: :nullify

  def item
    variation.presence || product
  end

  def title
    variation_id.present? ?
      "#{product.full_title} → #{variation.title}" :
      product.full_title
  end

  def link_purchased_products
    return unless sale.active?
    return if purchased_products.size >= qty

    available_purchased_products = PurchasedProduct.where(
      product_sale_id: nil,
      purchase: {product_id:}
    )
      .joins(:purchase)
      .limit(qty)

    available_purchased_products.update_all(product_sale_id: id)
  end
end
