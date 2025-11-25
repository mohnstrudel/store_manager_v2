# == Schema Information
#
# Table name: purchases
#
#  id              :bigint           not null, primary key
#  amount          :integer
#  item_price      :decimal(8, 2)
#  order_reference :string
#  payments_count  :integer          default(0), not null
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
  attribute :warehouse_id, :integer

  #
  # == Concerns
  #
  include HasAuditNotifications
  include Searchable

  #
  # == Extensions
  #
  extend FriendlyId

  #
  # == Configuration
  #
  audited associated_with: :supplier
  has_associated_audits
  friendly_id :full_title, use: :slugged
  set_search_scope :search,
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

  #
  # == Validations
  #
  validates :amount, presence: true
  validates :item_price, presence: true
  validates :supplier_id, presence: true

  #
  # == Associations
  #
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

  #
  # == Scopes
  #
  scope :unpaid, -> {
    includes(:supplier)
      .where
      .missing(:payments)
      .order(created_at: :asc)
  }

  #
  # == Class Methods
  #
  # (none)

  #
  # == Domain Methods
  #
  def paid
    @paid ||= payments ? payments.pluck(:value).sum : 0
  end

  def debt
    @total_cost ||= [total_cost - paid, 0].max
  end

  def item_debt
    debt / amount
  end

  def item_paid
    paid / amount
  end

  def progress
    return 0 if total_cost.zero?
    [paid * 100.0 / total_cost, 100].min
  end

  def total_cost
    item_price * amount + total_shipping
  end

  def total_shipping
    if purchase_items.loaded?
      purchase_items.sum { |item| item.shipping_price.to_f }
    else
      purchase_items.sum(:shipping_price).to_f
    end
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

  def unpaid?
    payments_count.zero?
  end

  def add_items_to_warehouse(warehouse_id)
    purchase_items_attributes = Array.new(amount) {
      {
        purchase_id: id,
        warehouse_id:,
        created_at: Time.current,
        updated_at: Time.current
      }
    }
    purchase_items.create!(purchase_items_attributes)
  end

  def link_with_sales
    linked_purchase_item_ids = PurchaseLinker.link(self)
    PurchasedNotifier.handle_product_purchase(
      purchase_item_ids: linked_purchase_item_ids
    )
  end
end
