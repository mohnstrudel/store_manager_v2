# frozen_string_literal: true

# == Schema Information
#
# Table name: purchase_items
#
#  id                  :bigint           not null, primary key
#  expenses            :decimal(8, 2)
#  height              :integer
#  length              :integer
#  shipping_cost       :decimal(8, 2)    default(0.0), not null
#  tracking_number     :string
#  weight              :integer
#  width               :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  purchase_id         :bigint
#  sale_item_id        :bigint
#  shipping_company_id :bigint
#  warehouse_id        :bigint           not null
#
class PurchaseItem < ApplicationRecord
  after_commit :update_purchase_shipping_total, if: :should_update_purchase_shipping?

  #
  # == Concerns
  #
  include HasAuditNotifications
  include HasPreviewImages
  include Searchable

  #
  # == Configuration
  #
  audited associated_with: :purchase
  set_search_scope :search,
    against: [:tracking_number],
    associated_against: {
      product: [:full_title],
      purchase: [:order_reference],
      sale: [:shopify_name, :woo_id],
      customer: [:email, :first_name, :last_name],
      shipping_company: [:name]
    },
    using: {
      tsearch: {prefix: true}
    }

  #
  # == Validations
  #
  validates :shipping_company_id,
    presence: true,
    if: -> { tracking_number.present? }

  #
  # == Associations
  #
  db_belongs_to :warehouse
  db_belongs_to :purchase

  belongs_to :sale_item, optional: true, counter_cache: true
  has_one :sale, through: :sale_item
  has_one :customer, through: :sale

  has_one :product, through: :purchase

  belongs_to :shipping_company, optional: true

  #
  # == Scopes
  #
  scope :ordered_by_updated_date, -> { order(updated_at: :desc) }

  scope :with_notification_details, -> {
    includes(
      sale: :customer,
      sale_item: [
        :product,
        edition: [:size, :version, :color]
      ]
    )
  }

  scope :without_sale_items_by_product, ->(product_id) {
    paid_priority = Arel.sql(
      "CASE WHEN purchases.payments_count > 0 THEN 0 ELSE 1 END ASC"
    )
    where(sale_item_id: nil)
      .joins(:purchase)
      .where(purchases: {product_id:})
      .order(paid_priority, created_at: :asc)
  }

  scope :includes_show_associations, -> { includes(media: {image_attachment: :blob}) }

  scope :includes_purchase_show_associations, -> {
    includes(:warehouse, :sale_item, purchase: :payments, sale: [:customer, :shopify_info, :woo_info])
  }

  scope :includes_warehouse_show_associations, -> {
    includes(:product, :shipping_company, sale: :customer, purchase: [:payments, :purchase_items])
  }

  scope :includes_shipping_company_show_associations, -> {
    includes(:product, :purchase, edition: [:color, :size, :version])
  }

  #
  # == Class Methods
  #

  #
  # == Domain Methods
  #
  def name
    purchase.full_title
  end

  def title
    "Purchase Item №#{id}"
  end

  def cost
    purchase.item_price.to_f + shipping_cost.to_f
  end

  def relocate_to(destination_id)
    update!(warehouse_id: destination_id)
  end

  def link_with(sale_item_id)
    update!(sale_item_id:)
  end

  private

  def should_update_purchase_shipping?
    previously_new_record? || destroyed? || saved_change_to_shipping_cost?
  end

  def update_purchase_shipping_total
    delta =
      if previously_new_record?
        shipping_cost
      elsif destroyed?
        -shipping_cost
      else
        saved_change_to_shipping_cost.last - saved_change_to_shipping_cost.first
      end

    return if delta.zero?

    purchase.with_lock do
      purchase.shipping_total += delta
      purchase.save!
    end
  end
end
