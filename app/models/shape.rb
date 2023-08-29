# == Schema Information
#
# Table name: shapes
#
#  id         :bigint           not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Shape < ApplicationRecord
  validates :title, presence: true

  has_many :products, dependent: :destroy
end
