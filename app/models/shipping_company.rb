# == Schema Information
#
# Table name: shipping_companies
#
#  id           :bigint           not null, primary key
#  name         :string
#  tracking_url :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class ShippingCompany < ApplicationRecord
  audited

  has_many :purchased_products, dependent: :nullify

  validates_db_uniqueness_of :name
  validates :tracking_url, presence: true
end
