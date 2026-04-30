# frozen_string_literal: true

FactoryBot.define do
  factory(:variant) do
    transient do
      woo_store_id { nil }
      shopify_store_id { nil }
    end

    product
    version
    sku { generate(:unique_sku) }
    woo_id { SecureRandom.alphanumeric(10) }
    shopify_id { SecureRandom.alphanumeric(10) }

    after(:create) do |variant, evaluator|
      variant.upsert_woo_info!(store_id: evaluator.woo_store_id || variant[:woo_id])
      variant.upsert_shopify_info!(store_id: evaluator.shopify_store_id || variant.shopify_id)
    end

    trait(:with_size) do
      transient do
        size_value { "1:4" }
      end

      after(:build) do |variant, evaluator|
        variant.size = create(:size, value: evaluator.size_value)
      end
    end

    trait(:with_version) do
      transient do
        version_value { "Deluxe" }
      end

      after(:build) do |variant, evaluator|
        variant.version = create(:version, value: evaluator.version_value)
      end
    end

    trait(:with_color) do
      transient do
        color_value { "Gold" }
      end

      after(:build) do |variant, evaluator|
        variant.color = create(:color, value: evaluator.color_value)
      end
    end
  end
end
