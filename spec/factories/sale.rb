# frozen_string_literal: true

FactoryBot.define do
  factory(:sale) do
    transient do
      woo_store_id { nil }
      shopify_store_id { nil }
      synced { false }
    end

    customer

    discount_total { BigDecimal("0.0") }
    note { "" }
    shipping_total { BigDecimal("20.0") }
    status { "processing" }
    total { BigDecimal("1060.0") }
    woo_created_at { "2023-11-20T08:38 UTC" }
    woo_updated_at { "2023-11-20T08:38 UTC" }

    woo_id { SecureRandom.alphanumeric(10) }
    shopify_id { SecureRandom.alphanumeric(10) }

    after(:create) do |sale, evaluator|
      if evaluator.synced || evaluator.woo_store_id
        sale.upsert_woo_info(store_id: evaluator.woo_store_id || sale[:woo_id])
      end

      if evaluator.synced || evaluator.shopify_store_id
        sale.upsert_shopify_info(store_id: evaluator.shopify_store_id || sale.shopify_id)
      end
    end

    trait :synced do
      synced { true }
    end
  end
end
