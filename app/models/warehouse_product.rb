# == Schema Information
#
# Table name: warehouse_products
#
#  id              :bigint           not null, primary key
#  height          :integer
#  length          :integer
#  price           :decimal(8, 2)
#  shipping_price  :decimal(8, 2)
#  tracking_number :string
#  weight          :integer
#  width           :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  product_id      :bigint           not null
#  warehouse_id    :bigint           not null
#
class WarehouseProduct < ApplicationRecord
  db_belongs_to :warehouse
  db_belongs_to :product
end
