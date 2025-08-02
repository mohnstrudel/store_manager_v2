# == Schema Information
#
# Table name: products
#
#  id           :bigint           not null, primary key
#  full_title   :string
#  image        :string
#  sku          :string
#  slug         :string
#  store_link   :string
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
  include Searchable
  include Shopable

  #
  # == Extensions
  #
  extend FriendlyId

  #
  # == Configuration
  #
  friendly_id :get_slug, use: :slugged
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
  validates_db_uniqueness_of :sku

  #
  # == Associations
  #
  db_belongs_to :franchise
  db_belongs_to :shape

  has_many :editions, dependent: :destroy, autosave: true

  has_many :product_brands, dependent: :destroy
  has_many :brands, through: :product_brands

  has_many :product_sizes, dependent: :destroy
  has_many :sizes, through: :product_sizes

  has_many :product_versions, dependent: :destroy
  has_many :versions, through: :product_versions

  has_many :product_colors, dependent: :destroy
  has_many :colors, through: :product_colors

  has_many :sale_items, dependent: :destroy
  has_many :sales, through: :sale_items

  has_many :purchases, dependent: :destroy
  has_many :purchase_items, through: :purchases
  accepts_nested_attributes_for :purchases

  #
  # == Scopes
  #
  scope :listed, -> {
    includes(editions: [:version, :color, :size])
      .with_attached_images
      .order(created_at: :desc)
  }

  #
  # == Class Methods
  #
  def self.generate_full_title(
    product,
    brand = nil
  )
    title_part = if product.title == product.franchise.title
      product.title
    else
      "#{product.franchise.title} — #{product.title}"
    end

    brands = if product.brands.size >= 1
      product.brands.pluck(:title).join(", ")
    end

    [
      title_part,
      brand&.title || brands.presence
    ].compact.join(" | ")
  end

  #
  # == Domain Methods
  #
  def update_full_title
    self.full_title = Product.generate_full_title(self)
    save
  end

  def get_slug
    sku.presence || full_title
  end

  def full_title_with_shop_id
    "#{full_title} | #{shop_id || "N/A"}"
  end

  def shopify_store_link
    "https://handsomecake.com/products/#{store_link}"
  end

  def active_sale_items
    sale_items
      .includes(purchase_items: :warehouse)
      .includes_details
      .active
      .order(created_at: :asc)
  end

  def completed_sale_items
    sale_items.includes_details.completed.order(created_at: :asc)
  end

  def editions_sale_items_size
    SaleItem
      .active
      .where(edition: editions)
      .group(:edition_id)
      .sum(:qty)
  end

  def editions_purchase_items_size
    Purchase
      .where(edition: editions)
      .group(:edition_id)
      .sum(:amount)
  end

  def build_editions
    return unless sizes.any? || versions.any? || colors.any?

    mark_absent_editions_for_destruction

    editions.build(edition_attributes)
  end

  def editions_with_title
    editions.includes_details.select { |edition| edition.title.present? }
  end

  private

  def mark_absent_editions_for_destruction
    editions.each do |edition|
      should_delete = (edition.size && sizes.exclude?(edition.size)) ||
        (edition.version && versions.exclude?(edition.version)) ||
        (edition.color && colors.exclude?(edition.color))
      edition.mark_for_destruction if should_delete
    end
  end

  def edition_attributes
    size_items = sizes.any? ? sizes : [nil]
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
