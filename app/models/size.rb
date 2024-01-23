# == Schema Information
#
# Table name: sizes
#
#  id         :bigint           not null, primary key
#  value      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Size < ApplicationRecord
  validates :value, presence: true

  has_many :product_sizes, dependent: :destroy
  has_many :products, through: :product_sizes

  def self.parse_size(product_title)
    size = product_title.match(size_match)
    size[0].tr("/", ":") if size.present?
  end

  def self.size_match
    /1[\/:]([3456]|3\.5|1|7)/
  end
end
