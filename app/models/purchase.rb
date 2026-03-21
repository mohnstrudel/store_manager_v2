# frozen_string_literal: true

# == Schema Information
#
# Table name: purchases
#
#  id              :bigint           not null, primary key
#  amount          :integer
#  item_price      :decimal(8, 2)
#  order_reference :string
#  paid            :decimal(8, 2)    default(0.0), not null
#  payments_count  :integer          default(0), not null
#  purchase_date   :datetime
#  shipping_total  :decimal(8, 2)    default(0.0), not null
#  slug            :string
#  synced          :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  edition_id      :bigint
#  product_id      :bigint
#  supplier_id     :bigint           not null
#
class Purchase < ApplicationRecord
  attribute :warehouse_id, :integer

  include Financials
  include HasAuditNotifications
  include Listing
  include Searchable
  include Warehousing
  include Titling

  extend FriendlyId

  audited associated_with: :supplier
  has_associated_audits

  friendly_id :full_title, use: :slugged
  paginates_per 50

  set_search_scope :search,
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

  validates :amount, presence: true
  validates :item_price, presence: true
  validates :supplier_id, presence: true

  db_belongs_to :supplier, inverse_of: :purchases
  belongs_to :product, optional: true, inverse_of: :purchases
  belongs_to :edition, optional: true, inverse_of: :purchases

  has_many :payments, dependent: :destroy, inverse_of: :purchase
  accepts_nested_attributes_for :payments

  has_many :purchase_items, dependent: :destroy, inverse_of: :purchase
  has_many :warehouses, through: :purchase_items

  has_many :sizes, through: :edition
  has_many :versions, through: :edition
  has_many :colors, through: :edition

  scope :unpaid, -> {
    includes(:supplier)
      .where
      .missing(:payments)
      .order(created_at: :asc)
  }
end
