# frozen_string_literal: true

FactoryBot.define do
  factory :purchase_expense do
    purchase_item
    description { "Extra tax" }
    amount { BigDecimal("10.00") }
  end
end
