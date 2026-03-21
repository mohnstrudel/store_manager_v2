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
  #
  # == Concerns
  #
  include HasAuditNotifications
  include HasPreviewImages
  include Listing
  include Searchable
  include SalesHistory
  include Shopable
  include StoreReferences

  #
  # == Extensions
  #
  extend FriendlyId

  #
  # == Configuration
  #
  friendly_id :find_slug_candidate, use: :slugged
  broadcasts_refreshes
  paginates_per 50
  audited associated_with: :franchise
  has_associated_audits
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

  #
  # == Callbacks
  #
  after_create :update_full_title

  #
  # == Validations
  #
  validates :title, presence: true
  validates :sku, presence: true
  validates_db_uniqueness_of :sku

  #
  # == Associations
  #
  has_rich_text :description
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
  accepts_nested_attributes_for :purchases

  #
  # == Class Methods
  #
  def self.generate_full_title(product)
    title_part = if product.title == product.franchise.title
      product.title
    else
      "#{product.franchise.title} — #{product.title}"
    end

    brands = if product.brands.exists?
      product.brands.pluck(:title).join(", ")
    end

    [
      title_part,
      brands
    ].compact_blank.join(" | ")
  end

  #
  # == Domain Methods
  #
  def update_full_title
    self.full_title = Product.generate_full_title(self)
    save
  end

  def find_slug_candidate
    sku.presence || full_title
  end

  def build_new_editions
    return create_base_model_edition if base_model_case?
    return unless sizes.any? || versions.any? || colors.any?

    editions.build(edition_attributes)
  end

  def fetch_editions_with_title
    editions.includes(:version, :color, :size).select { |edition| edition.title.present? }
  end

  private

  # Single size editions aren't real editions by our agreement
  def base_model_case?
    sizes.count == 1 && colors.empty? && versions.empty?
  end

  def create_base_model_edition
    attributes = {product_id: id}

    return if editions.exists?(attributes)

    editions.build(attributes)
  end

  def edition_attributes
    # Single size logic: don't use size if there's only 1
    # AND there are other attributes (versions or colors)
    # Base model case is handled separately in build_new_editions
    skip_single_size = sizes.count == 1 && (versions.any? || colors.any?)

    size_items = if skip_single_size
      [nil]
    elsif sizes.any?
      sizes
    else
      [nil]
    end

    version_items = versions.any? ? versions : [nil]
    color_items = colors.any? ? colors : [nil]

    edition_attributes = []

    size_items.each do |size|
      version_items.each do |version|
        color_items.each do |color|
          attributes = {
            product_id: id,
            size_id: size&.id,
            version_id: version&.id,
            color_id: color&.id
          }.compact_blank

          next if editions.exists?(attributes)

          edition_attributes << attributes
        end
      end
    end

    edition_attributes
  end
end
