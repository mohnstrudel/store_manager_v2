# == Schema Information
#
# Table name: sales
#
#  id             :bigint           not null, primary key
#  address_1      :string
#  address_2      :string
#  city           :string
#  company        :string
#  country        :string
#  discount_total :decimal(8, 2)
#  note           :string
#  postcode       :string
#  shipping_total :decimal(8, 2)
#  state          :string
#  status         :string
#  total          :decimal(8, 2)
#  woo_created_at :datetime
#  woo_updated_at :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  customer_id    :bigint           not null
#  woo_id         :string
#
class Sale < ApplicationRecord
  paginates_per 50

  belongs_to :customer

  has_many :product_sales, dependent: :destroy
  has_many :products, through: :product_sales

  accepts_nested_attributes_for :product_sales, allow_destroy: true

  def self.STATUSES
    ["pre-ordered", "processing", "cancelled", "failed", "completed"]
  end

  def self.sync_woo_orders
    SyncWooOrdersJob.perform_later
  end
end
