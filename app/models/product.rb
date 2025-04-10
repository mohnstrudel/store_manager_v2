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
  include HasPreviewImages
  include PgSearch::Model

  broadcasts_refreshes
  paginates_per 50

  extend FriendlyId
  friendly_id :get_slug, use: :slugged

  pg_search_scope :search,
    against: [:full_title, :woo_id],
    associated_against: {
      suppliers: [:title],
      sizes: [:value],
      versions: [:value],
      colors: [:value]
    },
    using: {
      tsearch: {prefix: true}
    }

  after_create :update_full_title

  validates :title, presence: true
  validates_db_uniqueness_of :sku

  db_belongs_to :franchise
  db_belongs_to :shape

  has_many :product_brands, dependent: :destroy
  has_many :brands, through: :product_brands

  has_many :product_suppliers, dependent: :destroy
  has_many :suppliers, through: :product_suppliers

  has_many :product_sizes, dependent: :destroy
  has_many :sizes, through: :product_sizes

  has_many :product_versions, dependent: :destroy
  has_many :versions, through: :product_versions

  has_many :product_colors, dependent: :destroy
  has_many :colors, through: :product_colors

  has_many :product_sales, dependent: :destroy
  has_many :sales, through: :product_sales

  has_many :variations, dependent: :destroy, autosave: true

  has_many :purchases, dependent: :destroy
  has_many :purchased_products, through: :purchases

  def update_full_title
    self.full_title = Product.generate_full_title(self)
    save
  end

  def self.generate_full_title(
    product,
    brand = nil
  )
    name = (product.title == product.franchise.title) ?
      product.title :
      "#{product.franchise.title} — #{product.title}"
    brands = product.brands.pluck(:title).join(", ")
    [
      name,
      brand.presence || brands.presence
    ].compact.join(" | ")
  end

  def prev_image_id(img_id)
    (images.where("id < ?", img_id).last || images.last).id
  end

  def next_image_id(img_id)
    (images.where("id > ?", img_id).first || images.first).id
  end

  def get_slug
    sku.presence || full_title
  end

  def woo_id_full_title
    woo_id = self.woo_id.presence || "N/A"
    "#{woo_id} | #{full_title}"
  end

  def shopify_store_link
    "https://handsomecake.com/products/#{store_link}"
  end

  def shopify_id_short
    shopify_id&.gsub("gid://shopify/Product/", "")
  end

  def build_variations
    return unless sizes.any? || versions.any? || colors.any?

    mark_absent_variations_for_destruction

    variations.build(variation_attributes)
  end

  private

  def mark_absent_variations_for_destruction
    variations.each do |variation|
      should_delete = (variation.size && sizes.exclude?(variation.size)) ||
        (variation.version && versions.exclude?(variation.version)) ||
        (variation.color && colors.exclude?(variation.color))
      variation.mark_for_destruction if should_delete
    end
  end

  def variation_attributes
    size_items = sizes.any? ? sizes : [nil]
    version_items = versions.any? ? versions : [nil]
    color_items = colors.any? ? colors : [nil]

    variation_attributes = []

    size_items.each do |size|
      version_items.each do |version|
        color_items.each do |color|
          attributes = {
            product_id: id,
            size_id: size&.id,
            version_id: version&.id,
            color_id: color&.id
          }.compact_blank

          next if variations.exists?(attributes)

          variation_attributes << attributes
        end
      end
    end

    variation_attributes
  end
end
