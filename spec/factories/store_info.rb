FactoryBot.define do
  factory(:store_info) do
    association :product
    name { :not_assigned }

    trait :shopify do
      name { :shopify }
    end

    trait :woo do
      name { :woo }
    end

    trait :with_store_product_id do
      store_product_id { "gid://shopify/Product/12345" }
    end

    trait :with_slug do
      slug { "test-product" }
    end

    trait :with_push_time do
      push_time { Time.current }
    end
  end
end
