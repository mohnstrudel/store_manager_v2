# frozen_string_literal: true
FactoryBot.define do
  factory(:purchase) do
    product
    supplier

    amount { 64 }
    item_price { BigDecimal("1030.0") }
    order_reference { "Y-1918791-F" }

    trait :unpaid do
      # No payments created - this creates purchases that will be picked up by the .unpaid scope
    end
  end
end
