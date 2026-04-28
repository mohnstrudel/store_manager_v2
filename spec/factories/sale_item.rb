# frozen_string_literal: true

FactoryBot.define do
  factory(:sale_item) do
    transient do
      woo_store_id { nil }
      shopify_store_id { nil }
    end

    price { BigDecimal("873.95") }
    qty { 1 }
    woo_id { SecureRandom.alphanumeric(10) }
    shopify_id { SecureRandom.alphanumeric(10) }
    product
    sale
    edition

    after(:create) do |sale_item, evaluator|
      if evaluator.woo_store_id.present? || sale_item[:woo_id].present?
        sale_item.upsert_woo_info!(store_id: evaluator.woo_store_id || sale_item[:woo_id])
      end

      sale_item.upsert_shopify_info!(store_id: evaluator.shopify_store_id || sale_item.shopify_id) if evaluator.shopify_store_id.present? || sale_item.shopify_id.present?
    end
  end
end
