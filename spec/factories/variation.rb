FactoryBot.define do
  factory(:variation) do
    product
    store_link { "https://store.handsomecake.com/link-id?variation=666" }
    woo_id { "666" }
    version

    trait(:with_size) do
      transient do
        size_value { "1:4" }
      end

      after(:build) do |variation, evaluator|
        variation.size = create(:size, value: evaluator.size_value)
      end
    end

    trait(:with_version) do
      transient do
        version_value { "Deluxe" }
      end

      after(:build) do |variation, evaluator|
        variation.version = create(:version, value: evaluator.version_value)
      end
    end

    trait(:with_color) do
      transient do
        color_value { "Gold" }
      end

      after(:build) do |variation, evaluator|
        variation.color = create(:color, value: evaluator.color_value)
      end
    end
  end
end
