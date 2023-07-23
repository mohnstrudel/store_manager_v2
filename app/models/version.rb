# == Schema Information
#
# Table name: versions
#
#  id         :bigint           not null, primary key
#  value      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Version < ApplicationRecord
  has_many :products
end
