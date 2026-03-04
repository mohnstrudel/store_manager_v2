# frozen_string_literal: true

FactoryBot.define do
  factory(:payment) do
    payment_date { Time.current }
    purchase
    value { BigDecimal("100.0") }
  end
end
