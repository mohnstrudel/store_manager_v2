FactoryBot.define do
  factory(:product_sale) do
    price { BigDecimal("873.95") }
    qty { 1 }
    woo_id { "7318" }
    product
    sale
    variation
  end
end
