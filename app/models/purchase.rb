# frozen_string_literal: true

# == Schema Information
#
# Table name: purchases
#
#  id              :bigint           not null, primary key
#  amount          :integer
#  item_price      :decimal(8, 2)
#  order_reference :string
#  paid            :decimal(8, 2)    default(0.0), not null
#  payments_count  :integer          default(0), not null
#  purchase_date   :datetime
#  shipping_total  :decimal(8, 2)    default(0.0), not null
#  slug            :string
#  synced          :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  product_id      :bigint
#  supplier_id     :bigint           not null
#  variant_id      :bigint
#
class Purchase < ApplicationRecord
  attribute :warehouse_id, :integer
  attribute :payment_value, :decimal

  include Financials
  include AuditNotifiable
  include Linkable
  include Placeable
  include Searchable
  include Warehousing
  include Titled
  include VariantAssignment

  extend FriendlyId

  audited associated_with: :supplier
  has_associated_audits

  friendly_id :full_title, use: :slugged
  paginates_per 50

  set_search_scope :search,
    against: [:order_reference],
    associated_against: {
      supplier: [:title],
      product: [:full_title],
      sizes: [:value],
      versions: [:value],
      colors: [:value]
    }

  validates :amount, presence: true
  validates :item_price, presence: true
  validates :supplier_id, presence: true
  validate :product_or_variant_present, on: :create

  db_belongs_to :supplier, inverse_of: :purchases

  belongs_to :product, optional: true, inverse_of: :purchases
  belongs_to :variant, optional: true, inverse_of: :purchases

  has_many :payments, dependent: :destroy, inverse_of: :purchase
  has_many :purchase_items, dependent: :destroy, inverse_of: :purchase
  has_many :purchase_expenses, through: :purchase_items
  has_many :warehouses, through: :purchase_items

  has_many :sizes, through: :variant
  has_many :versions, through: :variant
  has_many :colors, through: :variant

  scope :for_listing, -> {
    includes(
      :supplier,
      :payments,
      {product: {media: {image_attachment: :blob}}},
      purchase_items: [:warehouse],
      variant: [:color, :size, :version]
    )
  }

  scope :for_form_select, -> {
    includes(:product, :supplier).order(purchase_date: :desc, created_at: :desc)
  }

  scope :for_supplier_details, -> {
    includes(:product, :payments, variant: [:color, :size, :version])
  }

  scope :for_details, -> {
    includes(
      :supplier,
      :payments,
      {product: {media: {image_attachment: :blob}}},
      variant: [:color, :size, :version]
    )
  }

  private

  def product_or_variant_present
    errors.add(:base, "must have a product or variant") unless product_id? || variant_id?
  end
end
