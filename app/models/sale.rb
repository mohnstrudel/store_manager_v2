# frozen_string_literal: true

# == Schema Information
#
# Table name: sales
#
#  id                 :bigint           not null, primary key
#  address_1          :string
#  address_2          :string
#  cancel_reason      :string
#  cancelled_at       :datetime
#  city               :string
#  closed             :boolean          default(FALSE)
#  closed_at          :datetime
#  company            :string
#  confirmed          :boolean          default(FALSE)
#  country            :string
#  discount_total     :decimal(8, 2)
#  financial_status   :string
#  fulfillment_status :string
#  note               :string
#  postcode           :string
#  return_status      :string
#  shipping_total     :decimal(8, 2)
#  shopify_created_at :datetime
#  shopify_name       :string
#  shopify_updated_at :datetime
#  slug               :string
#  state              :string
#  status             :string
#  total              :decimal(8, 2)
#  woo_created_at     :datetime
#  woo_updated_at     :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  customer_id        :bigint           not null
#  shopify_id         :string
#  woo_id             :string
#
class Sale < ApplicationRecord
  #
  # == Concerns
  #
  include HasAuditNotifications
  include Listing
  include Searchable
  include ShopSync
  include Shopable
  include Statuses
  include Summaries

  #
  # == Extensions
  #
  extend FriendlyId

  #
  # == Configuration
  #
  friendly_id :full_title, use: :slugged
  paginates_per 50
  audited associated_with: :customer
  has_associated_audits
  set_search_scope :search,
    against: [:woo_id, :shopify_id, :status, :financial_status, :fulfillment_status, :note, :shopify_name],
    associated_against: {
      customer: [:email, :first_name, :last_name, :phone, :woo_id],
      products: [:full_title]
    },
    using: {
      tsearch: {prefix: true}
    }

  #
  # == Associations
  #
  db_belongs_to :customer, inverse_of: :sales

  has_many :sale_items, dependent: :destroy, inverse_of: :sale
  has_many :products, through: :sale_items

  accepts_nested_attributes_for :sale_items, allow_destroy: true

  def has_unlinked_sale_items?
    total_sold = sale_items.sum(:qty)
    total_purchased = sale_items.sum { |ps| ps.purchase_items.size }

    return if total_sold == total_purchased

    product_ids = sale_items.pluck(:product_id)

    PurchaseItem.without_sale_items_by_product(product_ids).exists?
  end

  def shop_created_at
    shopify_created_at || woo_created_at
  end

  def shop_updated_at
    shopify_info&.ext_updated_at || woo_updated_at
  end

  def link_with_purchase_items
    return unless active? || completed?

    sale_items.linkable.map do |sale_item|
      already_linked_size = sale_item.purchase_items.count
      remaining_size = sale_item.qty - already_linked_size

      next if remaining_size <= 0

      linkable_purchase_items = PurchaseItem
        .without_sale_items_by_product(sale_item.product_id)
        .limit(remaining_size)

      linked_purchase_items_ids = linkable_purchase_items.pluck(:id)

      linkable_purchase_items.each { it.link_with(sale_item.id) }

      linked_purchase_items_ids
    end.compact.flatten
  end

  def summary_for_warehouse
    [customer.full_name, address_1, address_2, postcode, city, country, customer.phone].compact_blank.join(", ")
  end
end
