FactoryBot.define do
  factory :purchase_item do
    warehouse
    purchase
    weight { 1 }
    length { 1 }
    width { 1 }
    height { 1 }
    expenses { "9.99" }
    shipping_price { "9.99" }
  end
end
