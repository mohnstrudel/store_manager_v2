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
#  phone          :string
#  postcode       :string
#  shipping_total :decimal(8, 2)
#  state          :string
#  status         :string
#  total          :decimal(8, 2)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  customer_id    :bigint           not null
#  woo_id         :string
#
FactoryBot.define do
  factory :sale do
    woo_id { "MyString" }
    status { "MyString" }
    discount_total { "9.99" }
    shipping_total { "9.99" }
    total { "9.99" }
    company { "MyString" }
    address_1 { "MyString" }
    address_2 { "MyString" }
    city { "MyString" }
    state { "MyString" }
    postcode { "MyString" }
    country { "MyString" }
    phone { "MyString" }
    note { "MyString" }
    customer { nil }
  end
end
