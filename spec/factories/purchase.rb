FactoryBot.define do
  factory(:purchase) do
    amount { 64 }
    item_price { BigDecimal("1030.0") }
    order_reference { "Y-1918791-F" }
    product_id { 89 }
    supplier_id { 3 }
  end
end
