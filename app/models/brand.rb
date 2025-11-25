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
  #
  # == Concerns
  #
  include Sanitizable
  include HasAuditNotifications

  #
  # == Extensions
  #
  # (none)

  #
  # == Configuration
  #
  audited
  has_associated_audits

  #
  # == Validations
  #
  validates :title, presence: true

  #
  # == Associations
  #
  has_many :product_brands, dependent: :destroy
  has_many :products, through: :product_brands

  #
  # == Callbacks
  #
  after_save :update_products

  #
  # == Class Methods
  #
  def self.parse_brand(product_title)
    product_title = smart_titleize(sanitize(product_title))
    brand_identifier = product_title.match(/(?:vo[nm]|by)\s+(.+)/i)
    brand_identifier[1] if brand_identifier.present?
  end

  #
  # == Domain Methods
  #
  # (none)

  private

  def update_products
    products.includes(:franchise, :brands).find_each(&:update_full_title)
  end
end
