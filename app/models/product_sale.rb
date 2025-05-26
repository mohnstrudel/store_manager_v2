# == Schema Information
#
# Table name: product_sales
#
#  id                       :bigint           not null, primary key
#  price                    :decimal(8, 2)
#  purchased_products_count :integer          default(0), not null
#  qty                      :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  edition_id               :bigint
#  product_id               :bigint           not null
#  sale_id                  :bigint           not null
#  shopify_id               :string
#  woo_id                   :string
#
class ProductSale < ApplicationRecord
  validates_db_uniqueness_of :woo_id, allow_nil: true

  db_belongs_to :product
  db_belongs_to :sale

  belongs_to :edition, optional: true

  has_many :purchased_products, dependent: :nullify

  scope :only_active, -> {
    joins(:sale).where(sales: {status: Sale.active_status_names})
  }

  scope :linkable, -> {
    where("qty > purchased_products_count")
  }

  def item
    edition.presence || product
  end

  def title
    edition_id.present? ?
      "#{product.full_title} → #{edition.title}" :
      product.full_title
  end

  def title_for_select
    status = sale.status&.titleize
    email = sale.customer.email
    pretty_sale_id = "Sale ID: #{sale_id}"
    pretty_woo_id = woo_id && "Woo ID: #{woo_id}"

    [id, status, title, email, pretty_sale_id, pretty_woo_id].compact.join(" | ")
  end
end
