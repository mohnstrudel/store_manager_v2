# frozen_string_literal: true

# == Schema Information
#
# Table name: brands
#
#  id         :bigint           not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Brand < ApplicationRecord
  include HasAuditNotifications
  include Parsing
  include Sanitizable

  audited
  has_associated_audits

  validates :title, presence: true

  has_many :product_brands, dependent: :destroy, inverse_of: :brand
  has_many :products, through: :product_brands

  after_save :update_products

  private

  def update_products
    products.includes(:franchise, :brands).find_each(&:update_full_title)
  end
end
