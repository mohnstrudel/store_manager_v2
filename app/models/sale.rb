# == Schema Information
#
# Table name: sales
#
#  id             :bigint           not null, primary key
#  address_1      :string
#  address_2      :string
#  city           :string
#  company        :string
#  country        :string
#  discount_total :decimal(8, 2)
#  note           :string
#  postcode       :string
#  shipping_total :decimal(8, 2)
#  state          :string
#  status         :string
#  total          :decimal(8, 2)
#  woo_created_at :datetime
#  woo_updated_at :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  customer_id    :bigint           not null
#  woo_id         :string
#
class Sale < ApplicationRecord
  paginates_per 50

  belongs_to :customer

  has_many :product_sales, dependent: :destroy
  has_many :products, through: :product_sales

  accepts_nested_attributes_for :product_sales, allow_destroy: true

  def title
    woo = woo_id.present? ? "Woo ID: #{woo_id}, " : ""
    email = customer.email.presence || ""
    woo + (email.present? ? "#{email}, " : "") + status
  end

  def select_title
    woo = woo_id.present? ? "Woo ID: #{woo_id}" : ""
    email = customer.email.presence || ""
    woo + " — " + email + " — " + status + ", total: $#{"%.2f" % total}"
  end

  def created
    woo_created_at || created_at
  end

  def self.list_new_statuses
    [
      "partially-paid",
      "po_fully_paid",
      "pre-ordered",
      "processing",
      "ready-to-fullfill",
      "im-zulauf",
      "container-shipped"
    ].freeze
  end

  def self.list_statuses
    # https://woocommerce.com/document/managing-orders/
    [
      "cancelled",
      "completed",
      "container-shipped",
      "failed",
      "im-zulauf",
      "on-hold",
      "partial-shipped",
      "partially-paid",
      "po_fully_paid",
      "pre-ordered",
      "processing",
      "ready-to-fullfill",
      "refunded",
      "updated-tracking"
    ].freeze
  end

  def self.sync_woo_orders
    SyncWooOrdersJob.perform_later
  end

  def self.update_order(sale)
    UpdateWooOrderJob.perform_later(sale)
  end

  def self.deserialize_woo_order(order)
    variations = Variation.types.values.flatten
    shipping = [order[:billing], order[:shipping]].reduce do |memo, el|
      el.each { |k, v| memo[k] = v unless v.empty? }
      memo
    end
    {
      sale: {
        woo_id: order[:id],
        status: order[:status],
        woo_created_at: DateTime.parse(order[:date_created]),
        woo_updated_at: DateTime.parse(order[:date_modified]),
        total: order[:total],
        shipping_total: order[:shipping_total],
        discount_total: order[:discount_total],
        note: order[:customer_note],
        address_1: shipping[:address_1],
        address_2: shipping[:address_2],
        city: shipping[:city],
        company: shipping[:company],
        country: shipping[:country],
        postcode: shipping[:postcode],
        state: shipping[:state]
      },
      customer: {
        woo_id: order[:customer_id],
        first_name: shipping[:first_name],
        last_name: shipping[:last_name],
        phone: shipping[:phone],
        email: shipping[:email]
      },
      products: order[:line_items].map { |i|
        {
          product_woo_id: i[:product_id],
          qty: i[:quantity],
          price: i[:price],
          order_woo_id: i[:id],
          variation_woo_id: i[:variation_id],
          variation: i[:meta_data].find { |meta| variations.include? meta[:display_key] }&.slice(:display_key, :display_value)
        }
      }
    }
  end
end
