# frozen_string_literal: true

FactoryBot.define do
  factory(:edition) do
    transient do
      woo_store_id { nil }
      shopify_store_id { nil }
    end

    product
    version
    sku { generate(:unique_sku) }
    woo_id { SecureRandom.alphanumeric(10) }
    shopify_id { SecureRandom.alphanumeric(10) }

    after(:create) do |edition, evaluator|
      edition.upsert_woo_info!(store_id: evaluator.woo_store_id || edition[:woo_id])
      edition.upsert_shopify_info!(store_id: evaluator.shopify_store_id || edition.shopify_id)
    end

    trait(:with_size) do
      transient do
        size_value { "1:4" }
      end

      after(:build) do |edition, evaluator|
        edition.size = create(:size, value: evaluator.size_value)
      end
    end

    trait(:with_version) do
      transient do
        version_value { "Deluxe" }
      end

      after(:build) do |edition, evaluator|
        edition.version = create(:version, value: evaluator.version_value)
      end
    end

    trait(:with_color) do
      transient do
        color_value { "Gold" }
      end

      after(:build) do |edition, evaluator|
        edition.color = create(:color, value: evaluator.color_value)
      end
    end
  end
end
