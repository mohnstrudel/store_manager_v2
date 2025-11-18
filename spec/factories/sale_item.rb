FactoryBot.define do
  factory(:sale_item) do
    price { BigDecimal("873.95") }
    qty { 1 }
    woo_id { SecureRandom.alphanumeric(10) }
    shopify_id { SecureRandom.alphanumeric(10) }
    product
    sale
    edition
  end
end
