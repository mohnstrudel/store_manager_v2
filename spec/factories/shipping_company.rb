FactoryBot.define do
  factory :shipping_company do
    name { "Shipping Company #{SecureRandom.alphanumeric(8)}" }
    tracking_url { "https://example.com/track/{tracking_number}" }
  end
end
