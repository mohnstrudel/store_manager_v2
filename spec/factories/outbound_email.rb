# frozen_string_literal: true

FactoryBot.define do
  factory :outbound_email do
    source { "link" }
    mail_kind { "order_status_updated" }
    sequence(:purchase_item_id) { |n| 1_000_000 + n }
    sequence(:sale_item_id) { |n| 2_000_000 + n }
    sequence(:warehouse_id) { |n| 3_000_000 + n }
    recipient { "buyer@example.com" }
    sender { "HandsomeCake Goodies <store@handsomecake.com>" }
    subject { "HandsomeCake Goodies. We updated your order" }
    body { "Hello Buyer,\r\n\r\nYour order moved." }

    trait :assumed_baseline do
      source { "baseline" }
      state { "assumed_baseline" }
      mail_kind { nil }
      recipient { nil }
      sender { nil }
      subject { nil }
      body { nil }
    end
  end
end
