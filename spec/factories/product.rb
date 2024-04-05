FactoryBot.define do
  factory(:product) do
    franchise
    shape
    store_link { nil }
    title { "Spirited Away" }
    woo_id { "26626" }

    factory(:product_with_brands) do
      transient do
        brand_title { "Studio Ghibli" }
        brands_count { 1 }
      end

      after(:create) do |product, evaluator|
        create_list(
          :brand,
          evaluator.brands_count,
          title: evaluator.brand_title,
          products: [product]
        )
        product.reload
      end
    end
  end
end
