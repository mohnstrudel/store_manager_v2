FactoryBot.define do
  factory(:product_sale) do
    price { BigDecimal("873.95") }
    qty { 1 }
    woo_id { rand(1..100000).to_s }
    product
    sale
    variation
  end
end
