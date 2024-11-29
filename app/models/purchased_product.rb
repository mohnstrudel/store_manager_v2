# == Schema Information
#
# Table name: purchased_products
#
#  id              :bigint           not null, primary key
#  expenses        :decimal(8, 2)
#  height          :integer
#  length          :integer
#  shipping_price  :decimal(8, 2)
#  tracking_number :string
#  weight          :integer
#  width           :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  product_sale_id :bigint
#  purchase_id     :bigint
#  warehouse_id    :bigint           not null
#
class PurchasedProduct < ApplicationRecord
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

  belongs_to :product_sale, optional: true
  has_one :sale, through: :product_sale

  has_one :product, through: :purchase

  scope :ordered_by_updated_date, -> { order(updated_at: :desc) }

  has_many_attached :images do |attachable|
    attachable.variant :preview,
      format: :webp,
      resize_to_limit: [800, 800],
      preprocessed: true
    attachable.variant :thumb,
      format: :webp,
      resize_to_limit: [300, 300],
      preprocessed: true
    attachable.variant :nano,
      format: :webp,
      resize_to_limit: [120, 120],
      preprocessed: true
  end

  def name
    purchase.full_title
  end

  def cost
    (price || 0) + (purchase.item_price || 0)
  end

  def self.unlinked_records(product_id)
    where(product_sale_id: nil)
      .joins(:purchase)
      .where(
        purchase: {product_id:}
      )
  end
end
