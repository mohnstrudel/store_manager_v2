# == Schema Information
#
# Table name: purchases
#
#  id              :bigint           not null, primary key
#  amount          :integer
#  item_price      :decimal(8, 2)
#  order_reference :string
#  purchase_date   :datetime
#  slug            :string
#  synced          :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  product_id      :bigint
#  supplier_id     :bigint           not null
#  variation_id    :bigint
#
class Purchase < ApplicationRecord
  extend FriendlyId
  friendly_id :full_title, use: :slugged

  include PgSearch::Model
  pg_search_scope :search,
    against: [:order_reference],
    associated_against: {
      supplier: [:title],
      product: [:full_title],
      sizes: [:value],
      versions: [:value],
      colors: [:value]
    },
    using: {
      tsearch: {prefix: true}
    }

  paginates_per 50

  validates :amount, presence: true
  validates :item_price, presence: true

  db_belongs_to :supplier
  belongs_to :product, optional: true
  belongs_to :variation, optional: true

  has_many :sizes, through: :variation
  has_many :versions, through: :variation
  has_many :colors, through: :variation

  has_many :payments, dependent: :destroy
  accepts_nested_attributes_for :payments

  def paid
    payments.pluck(:value).sum
  end

  def debt
    total_cost - paid
  end

  def progress
    paid / (total_cost * BigDecimal("0.01"))
  end

  def total_cost
    item_price * amount
  end

  def full_title
    "#{supplier.title} | #{product.full_title} | #{purchase_date.presence.strftime("%Y-%m-%d") || created_at.strftime("%Y-%m-%d")}"
  end

  def self.unpaid
    includes(:supplier)
      .where
      .missing(:payments)
      .order(created_at: :asc)
  end
end
