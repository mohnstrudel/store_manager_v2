FactoryBot.define do
  factory(:sale) do
    address_1 { "ToFactory: RubyParser exception parsing this attribute" }
    address_2 { "" }
    city { "Denkendorf" }
    company { "" }
    country { "DE" }
    customer_id { 1 }
    discount_total { BigDecimal("0.0") }
    note { "" }
    postcode { "73770" }
    shipping_total { BigDecimal("20.0") }
    state { "DE-BW" }
    status { "processing" }
    total { BigDecimal("1060.0") }
    woo_created_at { "2023-11-20T08:38 UTC" }
    woo_id { "26791" }
    woo_updated_at { "2023-11-20T08:38 UTC" }
  end
end
