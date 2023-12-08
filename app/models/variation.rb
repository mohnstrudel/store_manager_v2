# == Schema Information
#
# Table name: variations
#
#  id         :bigint           not null, primary key
#  store_link :string
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  color_id   :bigint
#  product_id :bigint           not null
#  size_id    :bigint
#  version_id :bigint
#  woo_id     :string
#
class Variation < ApplicationRecord
  belongs_to :size, optional: true
  belongs_to :version, optional: true
  belongs_to :color, optional: true
  db_belongs_to :product

  has_many :product_sales, dependent: :destroy
  has_many :purchases, dependent: :destroy

  after_create :calculate_title

  def self.types
    # Values should follow this rule: [English, German]
    {
      version: ["Version", "Variante"],
      size: ["Size", "Maßstab"],
      color: ["Color", "Farbe"],
      brand: ["Brand", "Marke"]
    }.freeze
  end

  def which
    [size, version, color].compact.first
  end

  private

  def calculate_title
    name = (product.title == product.franchise.title) ? product.title : "#{product.franchise.title} — #{product.title}"
    title_parts = [
      name,
      size&.value || product.sizes.pluck(:value).join(", "),
      version&.value || product.versions.pluck(:value).join(", "),
      color&.value || product.colors.pluck(:value).join(", "),
      "Resin #{product.shape.title}",
      product.brands.pluck(:title).join(", ")
    ]
    self.title = title_parts.compact_blank.join(" | ")
    save
  end
end
