# == Schema Information
#
# Table name: editions
#
#  id         :bigint           not null, primary key
#  sku        :string
#  store_link :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  color_id   :bigint
#  product_id :bigint           not null
#  shopify_id :string
#  size_id    :bigint
#  version_id :bigint
#  woo_id     :string
#
class Edition < ApplicationRecord
  audited associated_with: :product

  belongs_to :size, optional: true
  belongs_to :version, optional: true
  belongs_to :color, optional: true
  db_belongs_to :product

  has_many :product_sales, dependent: :destroy
  has_many :purchases, dependent: :destroy

  def self.types
    # Values should follow this rule: [English, German]
    {
      version: ["Version", "Variante"],
      size: ["Size", "Maßstab"],
      color: ["Color", "Farbe"],
      brand: ["Brand", "Marke"]
    }.freeze
  end

  def title
    [size&.value, version&.value, color&.value].compact.join(" | ")
  end

  def types_name
    types.join(" | ")
  end

  def types
    [size, version, color]
      .map { |i| i.presence && i.model_name.name }
      .compact
  end

  def types_size
    [size.presence, version.presence, color.presence].compact.size
  end

  def type_name_and_value
    [size, version, color].compact.map { |i| "#{i.model_name.name}: #{i.value}" }.join(", ")
  end

  def shopify_id_short
    shopify_id&.gsub("gid://shopify/ProductVariant/", "")
  end

  def shop_id
    shopify_id_short || woo_id
  end
end
