# == Schema Information
#
# Table name: warehouses
#
#  id                        :bigint           not null, primary key
#  cbm                       :string
#  container_tracking_number :string
#  courier_tracking_url      :string
#  external_name             :string
#  name                      :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
class Warehouse < ApplicationRecord
  has_many :warehouse_products, dependent: :destroy
  has_many :products, through: :warehouse_products

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
end
