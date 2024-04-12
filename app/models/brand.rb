# == Schema Information
#
# Table name: brands
#
#  id         :bigint           not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Brand < ApplicationRecord
  include Sanitizable

  validates :title, presence: true

  has_many :product_brands, dependent: :destroy
  has_many :products, through: :product_brands

  after_save :update_products

  def self.parse_brand(product_title)
    product_title = smart_titleize(sanitize(product_title))
    brand_identifier = product_title.match(/Vo[nm]\s+(.+)/)
    brand_identifier[1] if brand_identifier.present?
  end

  private

  def update_products
    products.each(&:set_full_title)
  end
end
