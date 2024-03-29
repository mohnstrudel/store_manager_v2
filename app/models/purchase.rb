# == Schema Information
#
# Table name: purchases
#
#  id              :bigint           not null, primary key
#  amount          :integer
#  full_title      :string
#  item_price      :decimal(8, 2)
#  order_reference :string
#  purchase_date   :datetime
#  synced          :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  product_id      :bigint
#  supplier_id     :bigint           not null
#  variation_id    :bigint
#
class Purchase < ApplicationRecord
  include PgSearch::Model
  pg_search_scope :search,
    against: [:full_title, :order_reference],
    associated_against: {
      supplier: [:title]
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

  def self.unpaid
    includes(:supplier)
      .where
      .missing(:payments)
      .order(created_at: :asc)
  end
end
