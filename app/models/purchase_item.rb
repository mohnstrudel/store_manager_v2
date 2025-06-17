# == Schema Information
#
# Table name: purchase_items
#
#  id                  :bigint           not null, primary key
#  expenses            :decimal(8, 2)
#  height              :integer
#  length              :integer
#  shipping_price      :decimal(8, 2)
#  tracking_number     :string
#  weight              :integer
#  width               :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  sale_item_id        :bigint
#  purchase_id         :bigint
#  shipping_company_id :bigint
#  warehouse_id        :bigint           not null
#
class PurchaseItem < ApplicationRecord
  #
  # == Concerns
  #
  include HasAuditNotifications
  include HasPreviewImages
  include Searchable

  #
  # == Extensions
  #
  # (none)

  #
  # == Configuration
  #
  audited associated_with: :purchase
  set_search_scope :search,
    associated_against: {
      product: [:full_title]
    },
    using: {
      tsearch: {prefix: true}
    }

  #
  # == Validations
  #
  validates :tracking_number,
    presence: true,
    if: -> { shipping_company_id.present? }

  validates :shipping_company_id,
    presence: true,
    if: -> { tracking_number.present? }

  #
  # == Associations
  #
  db_belongs_to :warehouse
  db_belongs_to :purchase

  belongs_to :sale_item, optional: true, counter_cache: true
  has_one :sale, through: :sale_item

  has_one :product, through: :purchase

  belongs_to :shipping_company, optional: true

  #
  # == Scopes
  #
  scope :ordered_by_updated_date, -> { order(updated_at: :desc) }

  scope :with_notification_details, -> {
    includes(
      sale: :customer,
      sale_item: [
        :product,
        edition: [:size, :version, :color]
      ]
    )
  }

  scope :without_sale_items, ->(product_id) {
    where(sale_item_id: nil)
      .joins(:purchase)
      .where(purchase: {product_id:})
  }

  #
  # == Class Methods
  #
  def self.linkable_for(product_id, limit:)
    without_sale_items(product_id).limit(limit)
  end

  #
  # == Domain Methods
  #
  def name
    purchase.full_title
  end

  def cost
    (price || 0) + (purchase.item_price || 0)
  end

  def relocate_to(destination_id)
    update!(warehouse_id: destination_id)
  end

  def link_with(sale_item_id)
    update!(sale_item_id:)
  end
end
