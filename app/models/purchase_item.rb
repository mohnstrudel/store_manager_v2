# frozen_string_literal: true

# == Schema Information
#
# Table name: purchase_items
#
#  id                   :bigint           not null, primary key
#  expenses             :decimal(8, 2)
#  height               :integer
#  length               :integer
#  shipped_at           :datetime
#  shipping_cost        :decimal(8, 2)    default(0.0), not null
#  tracking_number      :string
#  warehouse_arrived_at :datetime         not null
#  weight               :integer
#  width                :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  product_id           :bigint
#  purchase_id          :bigint
#  sale_item_id         :bigint
#  shipping_company_id  :bigint
#  variant_id           :bigint
#  warehouse_id         :bigint           not null
#
class PurchaseItem < ApplicationRecord
  include Revisable
  include Expenses
  include AuditNotifiable
  include Illustrated
  include Linkable
  include Financials
  include Notifications
  include Searchable
  include Shipping
  include Titled
  include Warehousing

  audited associated_with: :purchase
  audited max_audits: 100

  set_search_scope :search,
    against: [:tracking_number],
    associated_against: {
      product: [:full_title],
      purchase: [:order_reference],
      sale: [:shopify_name],
      woo_info: [:store_id],
      customer: [:email, :first_name, :last_name],
      shipping_company: [:name]
    }

  before_validation :derive_variant_identity

  db_belongs_to :warehouse, inverse_of: :purchase_items
  db_belongs_to :purchase, inverse_of: :purchase_items
  belongs_to :product, inverse_of: false
  belongs_to :variant, inverse_of: false
  belongs_to :sale_item, optional: true, counter_cache: true, inverse_of: :purchase_items

  has_one :sale, through: :sale_item
  has_one :customer, through: :sale
  has_one :woo_info, through: :sale, source: :woo_info

  scope :ordered_by_updated_date, -> { order(updated_at: :desc) }

  scope :with_media, -> { includes(media: {image_attachment: :blob}) }

  scope :preloaded, -> {
    includes(
      :audits,
      :warehouse,
      :shipping_company,
      :sale,
      :sale_item,
      purchase: [:supplier, :product, :variant],
      media: {image_attachment: :blob}
    )
  }

  scope :preloaded_for_purchase, -> {
    includes(
      :audits,
      :warehouse,
      :shipping_company,
      :purchase_expenses,
      :sale_item,
      purchase: :payments,
      sale: [:customer, :shopify_info, :woo_info, :shipping_address]
    ).ordered_by_updated_date
  }

  scope :preloaded_for_warehouse, -> {
    includes(
      :shipping_company,
      sale: [:customer, :shipping_address],
      purchase: [
        :payments,
        :purchase_items,
        {variant: [:size, :version, :color]},
        {product: :variants}
      ]
    )
  }

  scope :with_product_and_purchase, -> {
    includes(:product, :purchase)
  }

  scope :with_warehouse_sale_and_sale_item, -> {
    includes(
      :warehouse,
      sale: :customer,
      sale_item: [
        :product,
        variant: [:size, :version, :color]
      ]
    )
  }

  private

  def derive_variant_identity
    return unless purchase

    self.product_id = purchase.product_id
    self.variant_id = purchase.variant_id
  end
end
