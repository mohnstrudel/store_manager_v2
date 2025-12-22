# frozen_string_literal: true
FactoryBot.define do
  factory(:store_info) do
    association :storable, factory: :product
    store_name { :not_assigned }

    trait :for_edition do
      association :storable, factory: :edition
    end

    trait :shopify do
      store_name { :shopify }
    end

    trait :woo do
      store_name { :woo }
    end

    trait :with_store_id do
      store_id { "gid://shopify/Product/12345" }
    end

    trait :with_slug do
      slug { "test-product" }
    end

    trait :with_push_time do
      push_time { Time.current }
    end

    trait :with_price do
      price { 9.99 }
    end

    trait :with_store_product_id do
      with_store_id
      association :storable, factory: :product
    end
  end
end
