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
  after_create :create_purchased_products, :link_purchased_products

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

  has_many :purchased_products, dependent: :destroy
  has_many :warehouses, through: :purchased_products

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

  def which_variation
    variation ?
      variation.title :
      "-"
  end

  def date
    purchase_date || created_at
  end

  def self.unpaid
    includes(:supplier)
      .where
      .missing(:payments)
      .order(created_at: :asc)
  end

  def create_purchased_products
    warehouse = Warehouse.find_by(is_default: true)

    return if warehouse.nil?
    return if purchased_products.count >= amount

    amount.times do
      warehouse.purchased_products.create(purchase_id: id)
    end
  end

  def link_purchased_products
    return if purchased_products.count == 0

    available_product_sales = ProductSale.where(product_id:)

    return if available_product_sales.blank?

    unlinked_purchased_products_count = PurchasedProduct
      .where(product_sale_id: nil, purchase_id: id)
      .count

    available_product_sales.each do |ps|
      break if unlinked_purchased_products_count <= 0

      if unlinked_purchased_products_count > ps.qty
        unlinked_purchased_products_count -= ps.qty
        purchased_products
          .limit(ps.qty)
          .update_all(product_sale_id: ps.id)
      else
        unlinked_purchased_products_count = 0
        purchased_products
          .limit(unlinked_purchased_products_count)
          .update_all(product_sale_id: ps.id)
      end
    end
  end
end
