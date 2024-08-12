# == Schema Information
#
# Table name: purchased_products
#
#  id             :bigint           not null, primary key
#  height         :integer
#  length         :integer
#  price          :decimal(8, 2)
#  shipping_price :decimal(8, 2)
#  weight         :integer
#  width          :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  purchase_id    :bigint
#  warehouse_id   :bigint           not null
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
end
