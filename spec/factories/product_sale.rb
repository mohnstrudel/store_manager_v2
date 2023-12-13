FactoryBot.define do
  factory(:product_sale) do
    price { BigDecimal("873.95") }
    product_id { 598 }
    qty { 1 }
    sale_id { 1 }
    variation_id { nil }
    woo_id { "7318" }
  end
end
