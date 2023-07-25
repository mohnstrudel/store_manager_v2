# == Schema Information
#
# Table name: forms
#
#  id         :bigint           not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Form < ApplicationRecord
  validates :title, presence: true
  has_many :products
end
