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

  db_belongs_to :customer

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

  def self.wip_statuses
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

  def self.update_order(sale)
    UpdateWooOrderJob.perform_later(sale)
  end

  def self.has_wip_status?(status)
    wip_statuses.include?(status)
  end
end
