# frozen_string_literal: true
FactoryBot.define do
  factory(:edition) do
    product
    store_link { "https://store.handsomecake.com/link-id?edition=666" }
    woo_id { SecureRandom.alphanumeric(10) }
    shopify_id { SecureRandom.alphanumeric(10) }
    version

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
