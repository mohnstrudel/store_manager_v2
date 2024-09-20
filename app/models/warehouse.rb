# == Schema Information
#
# Table name: warehouses
#
#  id                        :bigint           not null, primary key
#  cbm                       :string
#  container_tracking_number :string
#  courier_tracking_url      :string
#  external_name             :string
#  is_default                :boolean          default(FALSE), not null
#  name                      :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
class Warehouse < ApplicationRecord
  has_many :purchased_products, dependent: :destroy
  has_many :purchases, through: :purchased_products

  has_many_attached :images do |attachable|
    attachable.variant :preview,
      format: :webp,
      resize_to_limit: [800, 800],
      preprocessed: true
    attachable.variant :thumb,
      format: :webp,
      resize_to_limit: [300, 300],
      preprocessed: true
    attachable.variant :nano,
      format: :webp,
      resize_to_limit: [120, 120],
      preprocessed: true
  end

  before_save :ensure_only_one_default

  validates :name, presence: true
  validates :external_name, presence: true

  private

  def ensure_only_one_default
    if is_default_changed? && is_default
      Warehouse
        .where(is_default: true)
        .where.not(id:)
        .update_all(is_default: false)
    end
  end
end
