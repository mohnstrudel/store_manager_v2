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
  validates :value, presence: true, uniqueness: true

  has_many :product_sizes, dependent: :destroy
  has_many :products, through: :product_sizes

  def self.parse_size(product_title)
    num_size = product_title.match(numeric_size_match)
    num_size[0].tr("/", ":") if num_size.present?
  end

  def self.sanitize_size(product_title)
    num_size = product_title.match(numeric_size_match)
    converted_title = num_size[0].tr("/", ":") if num_size.present?
    if converted_title
      product_title.sub(num_size[0], converted_title)
    else
      product_title
    end
  end

  def self.numeric_size_match
    /1[\/:]([3456]|3\.5|1|7)/
  end
end
