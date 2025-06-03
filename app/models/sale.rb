# == Schema Information
#
# Table name: sales
#
#  id                 :bigint           not null, primary key
#  address_1          :string
#  address_2          :string
#  cancel_reason      :string
#  cancelled_at       :datetime
#  city               :string
#  closed             :boolean          default(FALSE)
#  closed_at          :datetime
#  company            :string
#  confirmed          :boolean          default(FALSE)
#  country            :string
#  discount_total     :decimal(8, 2)
#  financial_status   :string
#  fulfillment_status :string
#  note               :string
#  postcode           :string
#  return_status      :string
#  shipping_total     :decimal(8, 2)
#  shopify_created_at :datetime
#  shopify_name       :string
#  shopify_updated_at :datetime
#  slug               :string
#  state              :string
#  status             :string
#  total              :decimal(8, 2)
#  woo_created_at     :datetime
#  woo_updated_at     :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  customer_id        :bigint           not null
#  shopify_id         :string
#  woo_id             :string
#
class Sale < ApplicationRecord
  audited associated_with: :customer
  has_associated_audits

  extend FriendlyId
  friendly_id :full_title, use: :slugged

  include PgSearch::Model
  pg_search_scope :search,
    against: [:woo_id, :shopify_id, :status, :financial_status, :fulfillment_status, :note, :shopify_name],
    associated_against: {
      customer: [:email, :first_name, :last_name, :phone, :woo_id],
      products: [:full_title]
    },
    using: {
      tsearch: {prefix: true}
    }

  paginates_per 50

  db_belongs_to :customer

  has_many :product_sales, dependent: :destroy
  has_many :products, through: :product_sales

  accepts_nested_attributes_for :product_sales, allow_destroy: true

  scope :except_cancelled_or_completed, -> {
    where.not(status: cancelled_status_names + completed_status_names)
  }

  def title
    email = customer.email.presence || ""
    [status&.titleize, email].compact.join(" | ")
  end

  def select_title
    name = customer.full_name.presence
    email = customer.email.presence
    woo = woo_id.presence
    total = total.presence || 0
    [name, email, status&.titleize, "$#{"%.2f" % total}", woo].compact.join(" | ")
  end

  def created
    woo_created_at || created_at
  end

  def full_title
    [customer.name_and_email, woo_id.presence].compact.join(" | ")
  end

  def active?
    self.class.active_status_names.include?(status)
  end

  def completed?
    self.class.completed_status_names.include?(status)
  end

  def self.active_status_names
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

  def self.completed_status_names
    ["completed", "updated-tracking"].freeze
  end

  def self.cancelled_status_names
    ["cancelled", "failed"].freeze
  end

  def self.status_names
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

  def self.inactive_status_names
    status_names - active_status_names - completed_status_names
  end

  def self.update_order(sale)
    UpdateWooOrderJob.perform_later(sale)
  end

  def has_unlinked_product_sales?
    total_sold = product_sales.sum(:qty)
    total_purchased = product_sales.sum { |ps| ps.purchased_products.size }

    return if total_sold == total_purchased

    product_ids = product_sales.pluck(:product_id)

    PurchasedProduct.without_product_sales(product_ids).exists?
  end

  def shop_created_at
    shopify_created_at || woo_created_at
  end

  def shop_updated_at
    shopify_updated_at || woo_updated_at
  end

  def shopify_id_short
    shopify_id&.gsub("gid://shopify/Order/", "")
  end

  def shop_id
    shopify_id_short || woo_id
  end
end
