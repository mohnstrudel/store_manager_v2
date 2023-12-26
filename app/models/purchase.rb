# == Schema Information
#
# Table name: purchases
#
#  id              :bigint           not null, primary key
#  amount          :integer
#  item_price      :decimal(8, 2)
#  order_reference :string
#  purchase_date   :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  product_id      :bigint
#  supplier_id     :bigint           not null
#  variation_id    :bigint
#
class Purchase < ApplicationRecord
  validates :amount, presence: true
  validates :item_price, presence: true

  db_belongs_to :supplier
  belongs_to :product, optional: true
  belongs_to :variation, optional: true

  has_many :payments, dependent: :destroy
  accepts_nested_attributes_for :payments

  delegate :full_title, to: :product

  def paid
    payments.pluck(:value).sum
  end

  def debt
    total_price - paid
  end

  def progress
    paid / (total_price * BigDecimal("0.01"))
  end

  def total_price
    item_price * amount
  end

  def self.unpaid
    where.missing(:payments).order(created_at: :asc)
  end

  def sync_purchases_from_file
    raw_purchases = JSON.parse(File.read("storage/purchases.json"), symbolize_names: true)
    product_job = SyncWooProductsJob.new
    raw_purchases.each do |purchase|
      title, franchise, shape = product_job.parse_product_name(purchase[:product])
      product = Product.find_or_create_by({
        title:,
        franchise: Franchise.find_or_create_by(title: franchise),
        shape: Shape.find_or_create_by(title: shape)
      })
      variation = if purchase[:version].present?
        unknown_colors = ["pink", "white", "weiß", "schwarz"]
        color = if purchase[:version].in?(unknown_colors)
          Color.find_or_create_by(value: purchase[:version].capitalize)
        else
          Color.find_by("lower(value) = ?", purchase[:version].downcase)
        end
        size = Size.find_by("lower(value) = ?", purchase[:version].downcase)
        version = Version.find_by("lower(value) = ?", purchase[:version].downcase)
        if {size:, color:, version:}.compact_blank.blank?
          Variation.find_or_create_by({
            product:,
            version: Version.create(value: purchase[:version])
          })
        else
          Variation.find_or_create_by(
            {product:}.merge({size:, color:, version:}.compact_blank)
          )
        end
      end
      purchase = Purchase.new({
        amount: purchase[:amount],
        order_reference: purchase[:orderreference],
        item_price: purchase[:itemprice],
        supplier: Supplier.find_or_create_by(title: purchase[:supplier]),
        purchase_date: Date.parse(purchase[:purchasedate]),
        product:,
        variation:
      })
      payments = purchase.select { |key, _| key.to_s.include?("paymentvalue") }
      payments.each do |key, value|
        date = purchase[:"paymentdate#{key[-1]}"]
        payment_date = if date.present?
          Date.parse(date)
        else
          Time.zone.today
        end
        purchase.payments.build({
          value:,
          payment_date:
        })
      end
      payments.save!
    end
  end
end
