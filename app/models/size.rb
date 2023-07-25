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
  has_many :products
end
