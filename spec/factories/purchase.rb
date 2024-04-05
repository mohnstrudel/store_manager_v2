FactoryBot.define do
  factory(:purchase) do
    product
    supplier

    amount { 64 }
    item_price { BigDecimal("1030.0") }
    order_reference { "Y-1918791-F" }
  end
end
