# frozen_string_literal: true
FactoryBot.define do
  factory(:payment) do
    payment_date { "2023-11-20T15:44 UTC" }
    purchase_id { 2 }
    value { BigDecimal("4841.59") }
  end
end
