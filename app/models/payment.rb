# == Schema Information
#
# Table name: payments
#
#  id           :bigint           not null, primary key
#  payment_date :datetime         not null
#  value        :decimal(8, 2)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  purchase_id  :bigint           not null
#
class Payment < ApplicationRecord
  validates :value, presence: true

  db_belongs_to :purchase, touch: true
end
