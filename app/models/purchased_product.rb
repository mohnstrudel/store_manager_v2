# == Schema Information
#
# Table name: purchased_products
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
#  product_sale_id     :bigint
#  purchase_id         :bigint
#  shipping_company_id :bigint
#  warehouse_id        :bigint           not null
#
class PurchasedProduct < ApplicationRecord
  audited associated_with: :purchase
  include HasAuditNotifications

  include HasPreviewImages
  include PgSearch::Model

  pg_search_scope :search,
    associated_against: {
      product: [:full_title]
    },
    using: {
      tsearch: {prefix: true}
    }

  db_belongs_to :warehouse
  db_belongs_to :purchase

  belongs_to :product_sale, optional: true, counter_cache: true
  has_one :sale, through: :product_sale

  has_one :product, through: :purchase

  belongs_to :shipping_company, optional: true

  validates :tracking_number,
    presence: true,
    if: -> { shipping_company_id.present? }

  validates :shipping_company_id,
    presence: true,
    if: -> { tracking_number.present? }

  scope :ordered_by_updated_date, -> { order(updated_at: :desc) }

  scope :with_notification_details, -> {
    includes(
      sale: :customer,
      product_sale: [
        :product,
        edition: [:size, :version, :color]
      ]
    )
  }

  scope :without_product_sales, ->(product_id) {
    where(product_sale_id: nil)
      .joins(:purchase)
      .where(purchase: {product_id:})
  }

  def self.linkable_for(product_id, limit:)
    without_product_sales(product_id).limit(limit)
  end

  def name
    purchase.full_title
  end

  def cost
    (price || 0) + (purchase.item_price || 0)
  end

  def relocate_to(destination_id)
    update!(warehouse_id: destination_id)
  end

  def link_with(product_sale_id)
    update!(product_sale_id:)
  end
end
