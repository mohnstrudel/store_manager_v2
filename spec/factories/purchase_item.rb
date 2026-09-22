# frozen_string_literal: true

FactoryBot.define do
  factory :purchase_item do
    warehouse
    purchase
    weight { 1 }
    length { 1 }
    width { 1 }
    height { 1 }
    expenses { "0" }
    shipping_cost { "9.99" }

    trait :with_direct_expense do
      transient do
        direct_expense_amount { BigDecimal("9.99") }
      end

      after(:create) do |purchase_item, evaluator|
        create(
          :purchase_expense,
          purchase_item:,
          amount: evaluator.direct_expense_amount
        )
      end
    end
  end
end
