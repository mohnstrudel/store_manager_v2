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
  include HasAuditNotifications
  include HasPreviewImages
  include Linking
  include Listing
  include Financials
  include Relocatable
  include Searchable
  include Shipping
  include Titling

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

  validates :shipping_company_id,
    presence: true,
    if: -> { tracking_number.present? }

  db_belongs_to :warehouse, inverse_of: :purchase_items
  db_belongs_to :purchase, inverse_of: :purchase_items
  belongs_to :sale_item, optional: true, counter_cache: true, inverse_of: :purchase_items
  belongs_to :shipping_company, optional: true, inverse_of: :purchase_items

  has_one :customer, through: :sale
  has_one :product, through: :purchase
  has_one :sale, through: :sale_item
end
