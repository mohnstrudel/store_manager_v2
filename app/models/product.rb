# == Schema Information
#
# Table name: products
#
#  id           :bigint           not null, primary key
#  title        :string
#  supplier_id  :bigint           not null
#  brand_id     :bigint           not null
#  franchise_id :bigint           not null
#  size_id      :bigint           not null
#  color_id     :bigint           not null
#  version_id   :bigint           not null
#  form_id      :bigint           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Product < ApplicationRecord
  validates :title, presence: true
  
  belongs_to :supplier
  belongs_to :brand
  belongs_to :franchise
  belongs_to :size
  belongs_to :color
  belongs_to :version
  belongs_to :form
end
