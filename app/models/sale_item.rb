# frozen_string_literal: true

# == Schema Information
#
# Table name: sale_items
#
#  id                   :bigint           not null, primary key
#  expected_revenue     :decimal(8, 2)
#  outstanding_revenue  :decimal(8, 2)
#  price                :decimal(8, 2)
#  purchase_items_count :integer          default(0), not null
#  qty                  :integer
#  received_revenue     :decimal(8, 2)
#  refunded_revenue     :decimal(8, 2)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  origin_sale_item_id  :bigint
#  product_id           :bigint           not null
#  sale_id              :bigint           not null
#  shopify_id           :string
#  shopify_variant_id   :string
#  variant_id           :bigint
#  woo_id               :string
#
class SaleItem < ApplicationRecord
  attr_accessor :_destroy

  include AuditNotifiable
  include Installments
  include Linkable
  include Profitability
  include RevenueAllocation
  include RevenueDefaults
  include Shopable
  include Syncable
  include Titled
  include VariantAssignment

  audited associated_with: :sale
  validate :validate_unique_woo_store_id

  db_belongs_to :product, inverse_of: :sale_items
  db_belongs_to :sale, inverse_of: :sale_items
  belongs_to :variant, optional: true, inverse_of: :sale_items

  has_many :purchase_items, dependent: :nullify, inverse_of: :sale_item

  scope :with_purchase_warehouses, -> { includes(purchase_items: :warehouse) }

  scope :preloaded_for_linking, -> {
    includes(
      :product,
      :shopify_info,
      :woo_info,
      sale: [:customer],
      variant: [:color, :size, :version]
    )
  }

  scope :preloaded, -> {
    includes(
      :product,
      purchase_items: :warehouse,
      sale: [
        :customer,
        :shopify_info,
        :woo_info,
        :shipping_address,
        :sale_items,
        {origin_payment_plans: [:origin_sale, {parts: :sale}]},
        {sale_payment_parts: {sale_payment_plan: [:origin_sale, {parts: :sale}]}}
      ],
      variant: [:version, :color, :size]
    )
  }

  scope :with_tracking_sources, -> {
    includes(:product, variant: [:version, :color, :size], purchase_items: :warehouse)
  }

  private

  def validate_unique_woo_store_id
    return if woo_store_id.blank?

    existing_store_info = StoreInfo
      .woo
      .where(storable_type: self.class.name, store_id: woo_store_id)
      .where.not(storable_id: id)
      .exists?

    errors.add(:woo_store_id, "has already been taken") if existing_store_info
  end
end
