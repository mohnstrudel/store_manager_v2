# frozen_string_literal: true

FactoryBot.define do
  factory :exchange_rate do
    date { Date.new(2026, 8, 21) }
    currency { "USD" }
    rate { BigDecimal("1.1250") }
    fetched_at { Time.current }
  end
end
