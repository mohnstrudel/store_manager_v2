# == Schema Information
#
# Table name: sale_items
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
class SaleItem < ApplicationRecord
  #
  # == Concerns
  #
  include HasAuditNotifications

  #
  # == Extensions
  #
  # (none)

  #
  # == Configuration
  #
  audited associated_with: :sale
  validates_db_uniqueness_of :woo_id, allow_nil: true

  #
  # == Validations
  #
  # (none)

  #
  # == Associations
  #
  db_belongs_to :product
  db_belongs_to :sale
  belongs_to :edition, optional: true

  has_many :purchase_items, dependent: :nullify

  #
  # == Scopes
  #
  scope :active, -> {
    joins(:sale).where(sales: {status: Sale.active_status_names})
  }

  scope :completed, -> {
    joins(:sale).where(sales: {status: Sale.completed_status_names})
  }

  scope :linkable, -> {
    where("qty > purchase_items_count")
  }

  scope :includes_details, -> {
    includes(:product, sale: :customer, edition: [:version, :color, :size])
  }

  #
  # == Class Methods
  #
  def self.linkable_for(purchase)
    active
      .linkable
      .where(
        purchase.edition_id.present? ?
          {edition_id: purchase.edition_id} :
          {product_id: purchase.product_id, edition_id: nil}
      )
  end

  #
  # == Domain Methods
  #
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
