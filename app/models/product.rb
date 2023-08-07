# == Schema Information
#
# Table name: products
#
#  id           :bigint           not null, primary key
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  brand_id     :bigint           not null
#  color_id     :bigint
#  franchise_id :bigint           not null
#  shape_id     :bigint           not null
#  size_id      :bigint
#  supplier_id  :bigint           not null
#  version_id   :bigint
#
class Product < ApplicationRecord
  validates :title, presence: true

  belongs_to :supplier
  belongs_to :brand
  belongs_to :franchise
  belongs_to :shape

  belongs_to :size, optional: true
  belongs_to :version, optional: true
  belongs_to :color, optional: true

  def full_title
    title_parts = [
      "#{franchise.title} — #{title}",
      "#{size&.value} resin #{shape.title}",
      brand.title,
      version&.value,
      color&.value
    ]
    title_parts.compact.join(" | ")
  end
end
