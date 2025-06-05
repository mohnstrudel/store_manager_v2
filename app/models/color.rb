# == Schema Information
#
# Table name: colors
#
#  id         :bigint           not null, primary key
#  value      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Color < ApplicationRecord
  audited
  include HasAuditNotifications

  validates :value, presence: true

  has_many :product_colors, dependent: :destroy
  has_many :products, through: :product_colors
end
