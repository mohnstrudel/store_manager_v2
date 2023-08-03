# == Schema Information
#
# Table name: franchises
#
#  id         :bigint           not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Franchise < ApplicationRecord
  validates :title, presence: true
  has_many :products
end
