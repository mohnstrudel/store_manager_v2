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

  def self.sync_purchases_from_file(file = File.read("purchases.json"))
    unknown_colors = ["pink", "white", "weiß", "schwarz"]
    size_match = /1[\/:]([3456]|3\.5|1|7)/
    resin_statue_match = /Resin Statue/i
    deposit_match = /Deposit/i
    copyright_match = /（Copyright）/i
    required = [
      :amount,
      :supplier,
      :itemprice,
      :orderreference,
      :product,
      :purchasedate
    ]
    errors = []
    product_job = SyncWooProductsJob.new
    parsed = JSON.parse(file, symbolize_names: true)
    parsed.each do |parsed_purchase|
      next if parsed_purchase[:canbeignored].present?
      empty_keys = required.select { |key| parsed_purchase[key].blank? }
      if empty_keys.any?
        errors.push({empty_keys:, parsed_purchase:})
        next
      end
      synced = Base64.encode64(parsed_purchase.to_s).last(64)
      next if Purchase.find_by(synced:).present?
      brand_title = Brand.parse_title(parsed_purchase[:product])
      product_name = parsed_purchase[:product]
        .sub(size_match, "")
        .sub(resin_statue_match, "")
        .sub(deposit_match, "")
        .sub(copyright_match, "")
        .strip
      brand = if brand_title.present?
        product_name = product_name.sub(/#{brand_title}/i, "").strip
        Brand.find_or_create_by(title: brand_title)
      end
      title, franchise_title, shape_title = product_job
        .parse_product_name(product_name)
      product_scaffold = {
        title:,
        franchise: Franchise.find_or_create_by(title: franchise_title),
        shape: Shape.find_or_create_by(title: shape_title)
      }
      product = if brand.present?
        brand.products.find_or_create_by(product_scaffold)
      else
        Product.find_or_create_by(product_scaffold)
      end
      variation, size, version, color = if parsed_purchase[:version].present?
        size = Size.find_by(
          "lower(value) = ?", parsed_purchase[:version].downcase
        )
        if size.blank?
          matched_size = parsed_purchase[:product].match(size_match)
          size = Size.find_or_create_by(value: matched_size[1])
        end
        version = Version.find_by(
          "lower(value) = ?", parsed_purchase[:version].downcase
        )
        color = if parsed_purchase[:version].in?(unknown_colors)
          Color.find_or_create_by(value: parsed_purchase[:version].capitalize)
        else
          Color.find_by("lower(value) = ?", parsed_purchase[:version].downcase)
        end
        variation = if {size:, color:, version:}.compact_blank.blank?
          Variation.find_or_create_by({
            product:,
            version: Version.create(value: parsed_purchase[:version])
          })
        else
          Variation.find_or_create_by(
            {product:}.merge({size:, color:, version:}.compact_blank)
          )
        end
        [variation, size, version, color]
      end
      full_title = Product.generate_full_title(
        product,
        brand&.title,
        size&.value,
        version&.value,
        color&.value
      )
      purchase_date = if parsed_purchase[:purchasedate].present?
        Date.parse(parsed_purchase[:purchasedate])
      else
        Time.zone.today
      end
      purchase = Purchase.new({
        amount: parsed_purchase[:amount],
        order_reference: parsed_purchase[:orderreference],
        item_price: parsed_purchase[:itemprice],
        supplier: Supplier.find_or_create_by(title: parsed_purchase[:supplier]),
        full_title:,
        purchase_date:,
        product:,
        variation:
      })
      payments = parsed_purchase.select { |key, _|
        key.to_s.include?("paymentvalue")
      }
      payments.each do |key, value|
        date = parsed_purchase[:"paymentdate#{key[-1]}"]
        payment_date = if date.present?
          Date.parse(date)
        else
          Time.zone.today
        end
        purchase.payments.build({
          value: value * parsed_purchase[:amount],
          payment_date:
        })
      end
      purchase.save!
    end
    if errors.any?
      Dir.mkdir("__debug") unless Dir.exist?("__debug")
      File.write("__debug/sync-purchase-errors.json", JSON.pretty_generate(errors))
    end
  end
end
