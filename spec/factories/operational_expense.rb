# frozen_string_literal: true

FactoryBot.define do
  factory :operational_expense do
    incurred_on { Time.zone.today }
    category { "Warehouse" }
    amount { BigDecimal("100.00") }
  end
end
