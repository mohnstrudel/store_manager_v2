# == Schema Information
#
# Table name: payments
#
#  id          :bigint           not null, primary key
#  value       :decimal(8, 2)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  purchase_id :bigint           not null
#
class Payment < ApplicationRecord
  validates :value, presence: true

  belongs_to :purchase
end
