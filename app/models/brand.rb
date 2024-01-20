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
  validates :title, presence: true

  has_many :product_brands, dependent: :destroy
  has_many :products, through: :product_brands

  def self.parse_title(product_title)
    brand_identifier = product_title.match(/vom|von/)
    if brand_identifier.present?
      product_title
        .split(brand_identifier[0])
        .last
        .strip
    end
  end
end
