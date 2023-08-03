# == Schema Information
#
# Table name: suppliers
#
#  id         :bigint           not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Supplier < ApplicationRecord
  validates :title, presence: true
  has_many :products
end
