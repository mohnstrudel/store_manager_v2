# frozen_string_literal: true

# == Schema Information
#
# Table name: sales
#
#  id                    :bigint           not null, primary key
#  cancel_reason         :string
#  cancelled_at          :datetime
#  closed                :boolean          default(FALSE)
#  closed_at             :datetime
#  confirmed             :boolean          default(FALSE)
#  discount_total        :decimal(8, 2)
#  exchange_rate_date    :date
#  expected_revenue      :decimal(8, 2)
#  financial_status      :string
#  fulfillment_status    :string
#  net_payment           :decimal(8, 2)
#  note                  :string
#  outstanding_revenue   :decimal(8, 2)
#  payment_due           :datetime
#  payment_gateway_names :string           default([]), not null, is an Array
#  payment_overdue       :boolean          default(FALSE), not null
#  payment_terms_name    :string
#  payment_terms_type    :string
#  presentment_currency  :string
#  received_revenue      :decimal(8, 2)
#  refunded_revenue      :decimal(8, 2)
#  return_status         :string
#  settlement_status     :string
#  shipping_total        :decimal(8, 2)
#  shop_currency         :string
#  shopify_created_at    :datetime
#  shopify_name          :string
#  shopify_updated_at    :datetime
#  slug                  :string
#  status                :string
#  total                 :decimal(8, 2)
#  usd_conversion_rate   :decimal(18, 10)
#  woo_created_at        :datetime
#  woo_updated_at        :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  customer_id           :bigint           not null
#  shopify_id            :string
#  woo_id                :string
#
class Sale < ApplicationRecord
  include Addressable
  include Filterable
  include FollowUpPayments
  include AuditNotifiable
  include Linkable
  include Profitability
  include RevenueAllocation
  include Revisable
  include Searchable
  include Settlement
  include Shopable
  include Statuses
  include Syncable
  include Taggable
  include Titled

  extend FriendlyId

  audited associated_with: :customer
  has_associated_audits

  friendly_id :full_title, use: :slugged
  paginates_per 50

  set_search_scope :search,
    against: [:shopify_id, :status, :financial_status, :fulfillment_status, :note, :shopify_name],
    associated_against: {
      woo_info: [:store_id],
      customer: [:email, :first_name, :last_name, :phone],
      products: [:full_title]
    }

  db_belongs_to :customer, inverse_of: :sales

  has_many :sale_items, dependent: :destroy, inverse_of: :sale
  has_many :products, through: :sale_items

  scope :with_payment_plans, -> {
    includes(
      {origin_payment_plans: [:origin_sale, {parts: :sale}]},
      {sale_payment_parts: {sale_payment_plan: [:origin_sale, {parts: :sale}]}}
    )
  }

  scope :preloaded_for_listing, -> {
    with_payment_plans.includes(
      :customer,
      :shopify_info,
      :woo_info,
      :shipping_address,
      :billing_address,
      :sales_tags,
      sale_items: [
        {product: {media: {image_attachment: :blob}}},
        {purchase_items: [:warehouse, purchase: :supplier]},
        {variant: [:version, :color, :size]}
      ]
    )
  }

  scope :with_items_and_addresses, -> {
    includes(:sale_items, :shipping_address, :billing_address)
  }

  scope :with_item_variant_options_and_addresses, -> {
    with_items_and_addresses.includes(
      sale_items: [
        {variant: [:color, :size, :version]},
        {product: {variants: [:color, :size, :version]}}
      ]
    )
  }

  scope :preloaded, -> {
    with_payment_plans.includes(
      :customer,
      :shopify_info,
      :woo_info,
      :shipping_address,
      :billing_address,
      sale_items: [
        {product: {media: {image_attachment: :blob}}},
        {purchase_items: [:warehouse, :shipping_company, {purchase: :supplier}]},
        {variant: [:version, :color, :size]}
      ]
    )
  }

  scope :with_customer_and_item_products, -> {
    includes(:customer, sale_items: [{product: {media: {image_attachment: :blob}}}, :variant])
  }
end
