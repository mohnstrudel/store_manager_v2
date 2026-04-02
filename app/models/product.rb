# frozen_string_literal: true

# == Schema Information
#
# Table name: products
#
#  id           :bigint           not null, primary key
#  full_title   :string
#  image        :string
#  sku          :string
#  slug         :string
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  franchise_id :bigint           not null
#  shape_id     :bigint           not null
#  shopify_id   :string
#  woo_id       :string
#
class Product < ApplicationRecord
  include EditionGeneration
  include HasAuditNotifications
  include HasPreviewImages
  include Listing
  include Editing
  include SalesHistory
  include Searchable
  include Shopable
  include StoreReferences
  include Titling

  extend FriendlyId

  audited associated_with: :franchise
  has_associated_audits

  broadcasts_refreshes
  friendly_id :find_slug_candidate, use: :slugged
  paginates_per 50

  set_search_scope :search,
    against: [:full_title, :woo_id],
    associated_against: {
      sizes: [:value],
      versions: [:value],
      colors: [:value]
    },
    using: {
      tsearch: {prefix: true}
    }

  validates :title, presence: true
  validates :sku, presence: true
  validates_db_uniqueness_of :sku
  validates_associated :editions

  db_belongs_to :franchise, inverse_of: :products
  db_belongs_to :shape, inverse_of: :products

  has_many :editions, dependent: :destroy, autosave: true, inverse_of: :product

  has_many :product_brands, dependent: :destroy, inverse_of: :product
  has_many :brands, through: :product_brands

  has_many :product_sizes, dependent: :destroy, inverse_of: :product
  has_many :sizes, through: :product_sizes
  has_many :product_versions, dependent: :destroy, inverse_of: :product
  has_many :versions, through: :product_versions

  has_many :product_colors, dependent: :destroy, inverse_of: :product
  has_many :colors, through: :product_colors

  has_many :sale_items, dependent: :destroy, inverse_of: :product
  has_many :sales, through: :sale_items

  has_many :purchases, dependent: :destroy, inverse_of: :product
  has_many :purchase_items, through: :purchases

  has_rich_text :description
end
