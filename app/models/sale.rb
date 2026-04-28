# frozen_string_literal: true

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
  include Editing
  include HasAuditNotifications
  include Linking
  include Listing
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

  def created_at_for_display
    woo_created_at || created_at
  end
end
