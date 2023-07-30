# == Schema Information
#
# Table name: products
#
#  id           :bigint           not null, primary key
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  brand_id     :bigint           not null
#  color_id     :bigint           not null
#  franchise_id :bigint           not null
#  shape_id     :bigint           not null
#  size_id      :bigint           not null
#  supplier_id  :bigint           not null
#  version_id   :bigint           not null
#
class Product < ApplicationRecord
  validates :title, presence: true

  belongs_to :supplier
  belongs_to :brand
  belongs_to :franchise
  belongs_to :size
  belongs_to :color
  belongs_to :version
  belongs_to :shape

  def full_name
    "#{self.franchise.title} — #{self.title} | #{self.size.value} resin #{self.shape.title} | from #{self.brand.title} | #{self.version.value} | #{self.color.value}"
  end
end
