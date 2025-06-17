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
#  edition_id      :bigint
#  product_id      :bigint
#  supplier_id     :bigint           not null
#
class Purchase < ApplicationRecord
  audited associated_with: :supplier
  has_associated_audits
  include HasAuditNotifications

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
  belongs_to :edition, optional: true

  has_many :sizes, through: :edition
  has_many :versions, through: :edition
  has_many :colors, through: :edition

  has_many :payments, dependent: :destroy
  accepts_nested_attributes_for :payments

  has_many :purchase_items, dependent: :destroy
  has_many :warehouses, through: :purchase_items

  scope :unpaid, -> {
    includes(:supplier)
      .where
      .missing(:payments)
      .order(created_at: :asc)
  }

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
    date = purchase_date || created_at
    "#{supplier.title} | #{product.full_title} | #{date&.strftime("%Y-%m-%d")}"
  end

  def which_edition
    edition ?
      edition.title :
      "-"
  end

  def date
    purchase_date || created_at
  end

  def create_purchase_items_in(warehouse)
    Array.new(amount) do
      warehouse.purchase_items.create(purchase_id: id)
    end
  end
end
