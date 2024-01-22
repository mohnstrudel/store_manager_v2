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
    brand_identifier = product_title.match(/vo[nm]\s+(.+)/)
    studio_identifier = product_title.match(/(.*?studios|.*?studio)\s*(.*)/i)
    if brand_identifier.present?
      brand_identifier[1]
    elsif studio_identifier.present?
      studio_identifier[0]
    else
      brand_titles = Brand.pluck(:title)
      brand_titles.find { |title|
        product_title.match(title)
      }
    end
  end
end
