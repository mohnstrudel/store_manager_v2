# == Schema Information
#
# Table name: products
#
#  id           :bigint           not null, primary key
#  full_title   :string
#  image        :string
#  store_link   :string
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  franchise_id :bigint           not null
#  shape_id     :bigint           not null
#  woo_id       :string
#
class Product < ApplicationRecord
  broadcasts_refreshes
  paginates_per 50

  include PgSearch::Model

  pg_search_scope :search,
    against: [:full_title, :woo_id],
    using: {
      tsearch: {prefix: true}
    }

  after_create :set_full_title

  validates :title, presence: true

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

  has_many :purchases, dependent: :destroy
  has_many :variations, dependent: :destroy

  has_many_attached :images do |attachable|
    attachable.variant :preview,
      format: :webp,
      resize_to_limit: [800, 800],
      preprocessed: true
    attachable.variant :thumb,
      format: :webp,
      resize_to_limit: [300, 300],
      preprocessed: true
    attachable.variant :nano,
      format: :webp,
      resize_to_limit: [120, 120],
      preprocessed: true
  end

  def set_full_title
    self.full_title = Product.generate_full_title(self)
    save
  end

  def self.generate_full_title(
    product,
    brand = nil,
    size = nil,
    version = nil,
    color = nil
  )
    name = (product.title == product.franchise.title) ?
      product.title :
      "#{product.franchise.title} — #{product.title}"
    format_values = ->(product) { product&.pluck(:value)&.join(", ") }
    sizes, versions, colors =
      [
        format_values.call(product.sizes),
        format_values.call(product.versions),
        format_values.call(product.colors)
      ]
    brands = product.brands.pluck(:title).join(", ")
    [
      name,
      size.presence || sizes.presence,
      version.presence || versions.presence,
      color.presence || colors.presence,
      "Resin #{product.shape.title}",
      brand.presence || brands.presence
    ].compact.join(" | ")
  end

  def prev_image_id(img_id)
    (images.where("id < ?", img_id).last || images.last).id
  end

  def next_image_id(img_id)
    (images.where("id > ?", img_id).first || images.first).id
  end
end
