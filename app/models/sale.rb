# frozen_string_literal: true

# == Schema Information
#
# Table name: sales
#
#  id                    :bigint           not null, primary key
#  cancel_reason         :string
#  cancelled_at          :datetime
#  closed                :boolean          default(FALSE)
#  closed_at             :datetime
#  confirmed             :boolean          default(FALSE)
#  discount_total        :decimal(8, 2)
#  expected_revenue      :decimal(8, 2)
#  financial_status      :string
#  fulfillment_status    :string
#  net_payment           :decimal(8, 2)
#  note                  :string
#  outstanding_revenue   :decimal(8, 2)
#  payment_due           :datetime
#  payment_gateway_names :string           default([]), not null, is an Array
#  payment_overdue       :boolean          default(FALSE), not null
#  payment_terms_name    :string
#  payment_terms_type    :string
#  received_revenue      :decimal(8, 2)
#  refunded_revenue      :decimal(8, 2)
#  return_status         :string
#  shipping_total        :decimal(8, 2)
#  shopify_created_at    :datetime
#  shopify_name          :string
#  shopify_updated_at    :datetime
#  slug                  :string
#  status                :string
#  total                 :decimal(8, 2)
#  woo_created_at        :datetime
#  woo_updated_at        :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  customer_id           :bigint           not null
#  shopify_id            :string
#  woo_id                :string
#
class Sale < ApplicationRecord
  include Addresses
  include BookedRevenue
  include Editing
  include HasAuditNotifications
  include Linking
  include Listing
  include Profitability
  include RevenueAllocation
  include Searchable
  include ShopSync
  include Shopable
  include Statuses
  include Titling

  extend FriendlyId

  audited associated_with: :customer
  has_associated_audits

  friendly_id :full_title, use: :slugged
  paginates_per 50

  set_search_scope :search,
    against: [:shopify_id, :status, :financial_status, :fulfillment_status, :note, :shopify_name],
    associated_against: {
      woo_info: [:store_id],
      customer: [:email, :first_name, :last_name, :phone],
      products: [:full_title]
    }

  db_belongs_to :customer, inverse_of: :sales

  has_many :sale_items, dependent: :destroy, inverse_of: :sale
  has_many :products, through: :sale_items
  has_many :origin_payment_plans,
    class_name: "SalePaymentPlan",
    foreign_key: :origin_sale_id,
    dependent: :nullify,
    inverse_of: :origin_sale
  has_many :sale_payment_parts, dependent: :nullify, inverse_of: :sale

  def created_at_for_display
    woo_created_at || created_at
  end

  def partially_paid?
    received_revenue.to_d.positive? && outstanding_revenue.to_d.positive?
  end

  def payment_plans_for_display
    (origin_payment_plans.to_a + sale_payment_parts.map(&:sale_payment_plan))
      .uniq(&:id)
      .sort_by { |plan| [plan.created_at, plan.id] }
  end

  def follow_up_payment?
    payment_plans_for_display.any? { |plan| plan.origin_sale_id != id && plan.part_number_for(self).present? }
  end
end
