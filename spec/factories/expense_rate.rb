# frozen_string_literal: true

FactoryBot.define do
  factory :expense_rate do
    sequence(:name) { |n| "Expense #{n}" }
    rate_percent { BigDecimal("15.0") }
  end
end
