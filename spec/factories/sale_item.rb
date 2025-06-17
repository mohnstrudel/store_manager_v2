FactoryBot.define do
  factory(:sale_item) do
    price { BigDecimal("873.95") }
    qty { 1 }
    woo_id { SecureRandom.alphanumeric(5) }
    product
    sale
    edition
  end
end
