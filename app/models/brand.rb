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
end
