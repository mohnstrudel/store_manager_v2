# == Schema Information
#
# Table name: suppliers
#
#  id         :bigint           not null, primary key
#  slug       :string
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Supplier < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged

  validates :title, presence: true

  has_many :product_suppliers, dependent: :destroy
  has_many :products, through: :product_suppliers

  has_many :purchases, dependent: :destroy
end
