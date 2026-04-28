# frozen_string_literal: true

FactoryBot.define do
  factory(:sale) do
    transient do
      woo_store_id { nil }
      shopify_store_id { nil }
    end

    customer

    address_1 { "ToFactory: RubyParser exception parsing this attribute" }
    address_2 { "" }
    city { "Denkendorf" }
    company { "" }
    country { "DE" }
    discount_total { BigDecimal("0.0") }
    note { "" }
    postcode { "73770" }
    shipping_total { BigDecimal("20.0") }
    state { "DE-BW" }
    status { "processing" }
    total { BigDecimal("1060.0") }
    woo_created_at { "2023-11-20T08:38 UTC" }
    woo_updated_at { "2023-11-20T08:38 UTC" }

    woo_id { SecureRandom.alphanumeric(10) }
    shopify_id { SecureRandom.alphanumeric(10) }

    after(:create) do |sale, evaluator|
      sale.upsert_woo_info!(store_id: evaluator.woo_store_id || sale[:woo_id])
      sale.upsert_shopify_info!(store_id: evaluator.shopify_store_id || sale.shopify_id)
    end
  end
end
