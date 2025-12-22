# frozen_string_literal: true
# == Schema Information
#
# Table name: sale_items
#
#  id                   :bigint           not null, primary key
#  price                :decimal(8, 2)
#  purchase_items_count :integer          default(0), not null
#  qty                  :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  edition_id           :bigint
#  product_id           :bigint           not null
#  sale_id              :bigint           not null
#  shopify_id           :string
#  woo_id               :string
#
class SaleItem < ApplicationRecord
  # TODO: Remove after merging the Auth PR #141
  self.ignored_columns += ["purchased_products_count"]
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

  scope :with_details, -> {
    includes(:product, sale: :customer, edition: [:version, :color, :size])
  }

  scope :with_purchase_details, -> {
    includes(:product, edition: [:version, :color, :size], purchase_items: :warehouse)
  }

  #
  # == Class Methods
  #
  def self.linkable_with(purchase)
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
  def resolve_sold_item
    edition.presence || product
  end

  def title
    edition_id.present? ?
      "#{product.full_title} → #{edition.title}" :
      product.full_title
  end

  def build_title_for_select
    status = sale.status&.titleize
    email = sale.customer.email
    pretty_sale_id = "Sale ID: #{sale_id}"
    pretty_woo_id = woo_id && "Woo ID: #{woo_id}"

    [id, status, title, email, pretty_sale_id, pretty_woo_id].compact.join(" | ")
  end
end
