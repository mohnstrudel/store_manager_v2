# == Schema Information
#
# Table name: products
#
#  id           :bigint           not null, primary key
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  franchise_id :bigint           not null
#  shape_id     :bigint           not null
#  woo_id       :string
#
class Product < ApplicationRecord
  paginates_per 50

  validates :title, presence: true

  belongs_to :franchise
  belongs_to :shape

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

  def full_title
    values_from = ->(i) { i&.pluck(:value)&.join(", ") }
    sizes_string = values_from.call(sizes)
    versions_string = values_from.call(versions)
    brands_string = brands.pluck(:title).join(", ")
    colors_string = values_from.call(colors)
    title_parts = [
      "#{franchise.title} — #{title}",
      "#{[sizes_string.presence, versions_string.presence].compact.join(" — ")} resin #{shape.title}",
      brands_string.presence,
      colors_string.presence
    ]
    title_parts.compact.join(" | ")
  end

  def self.sync_woo_products
    SyncWooProductsJob.perform_later
  end
end
