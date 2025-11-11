FactoryBot.define do
  factory(:product) do
    franchise
    shape
    store_link { nil }
    title { "Spirited Away" }
    woo_id { SecureRandom.alphanumeric(10) }
    shopify_id { SecureRandom.alphanumeric(10) }

    trait :with_brand do
      brand
    end

    trait :with_edition do
      edition
    end

    factory(:product_with_brands) do
      transient do
        brand_title { "Studio Ghibli" }
        brands_count { 1 }
      end

      before(:create) do |product, evaluator|
        existing_brand = Brand.find_by(title: evaluator.brand_title)

        if existing_brand
          product.brands << existing_brand
        else
          create_list(
            :brand,
            evaluator.brands_count,
            title: evaluator.brand_title,
            products: [product]
          )
        end
      end
    end
  end
end
