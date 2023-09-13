# == Schema Information
#
# Table name: product_sales
#
#  id         :bigint           not null, primary key
#  price      :decimal(8, 2)
#  qty        :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  product_id :bigint           not null
#  sale_id    :bigint           not null
#
FactoryBot.define do
  factory :product_sale do
    price { "9.99" }
    qty { 1 }
    product { nil }
    sale { nil }
  end
end
