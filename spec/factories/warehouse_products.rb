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
FactoryBot.define do
  factory :warehouse_product do
    warehouse { nil }
    product { nil }
    weight { 1 }
    length { 1 }
    width { 1 }
    height { 1 }
    price { "9.99" }
    shipping_price { "9.99" }
    tracking_number { "MyString" }
  end
end
