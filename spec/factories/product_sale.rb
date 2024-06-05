FactoryBot.define do
  factory(:product_sale) do
    price { BigDecimal("873.95") }
    qty { 1 }
    woo_id { SecureRandom.alphanumeric(5) }
    product
    sale
    variation
  end
end
