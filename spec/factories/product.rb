# frozen_string_literal: true

FactoryBot.define do
  sequence :unique_sku do |n|
    "sku-#{n}"
  end

  factory(:product) do
    franchise
    shape
    title { "Spirited Away" }
    woo_id { SecureRandom.alphanumeric(10) }
    shopify_id { SecureRandom.alphanumeric(10) }

    after(:build) do |product|
      product.full_title = product.generate_full_title
    end

    after(:create) do |product|
      create(:store_info, :woo, storable: product, store_id: product.woo_id)
      create(:store_info, :shopify, storable: product, store_id: product.shopify_id)
    end

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
