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

  scope :only_active, -> {
    joins(:sale).where(sales: {status: Sale.active_status_names})
  }

  def item
    variation.presence || product
  end

  def title
    variation_id.present? ?
      "#{product.full_title} → #{variation.title}" :
      product.full_title
  end

  def title_for_select
    status = sale.status&.titleize
    email = sale.customer.email
    pretty_sale_id = "Sale ID: #{sale_id}"
    pretty_woo_id = woo_id && "Woo ID: #{woo_id}"

    [id, status, title, email, pretty_sale_id, pretty_woo_id].compact.join(" | ")
  end

  def link_purchased_products
    return unless sale.active?
    return if purchased_products.size >= qty

    purchased_product_ids = PurchaseSaleLinker.new(sale:).link

    Notifier.new(purchased_product_ids:).handle_product_purchase
  end
end
