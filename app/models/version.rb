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
  audited
  include HasAuditNotifications

  validates :value, presence: true

  has_many :product_versions, dependent: :destroy
  has_many :products, through: :product_versions
end
