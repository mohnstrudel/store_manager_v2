# == Schema Information
#
# Table name: purchased_products
#
#  id              :bigint           not null, primary key
#  height          :integer
#  length          :integer
#  price           :decimal(8, 2)
#  shipping_price  :decimal(8, 2)
#  weight          :integer
#  width           :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  product_sale_id :bigint
#  purchase_id     :bigint
#  warehouse_id    :bigint           not null
#
FactoryBot.define do
  factory :purchased_product do
    warehouse
    purchase
    weight { 1 }
    length { 1 }
    width { 1 }
    height { 1 }
    price { "9.99" }
    shipping_price { "9.99" }
  end
end
