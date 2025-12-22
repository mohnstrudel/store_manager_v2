# frozen_string_literal: true

FactoryBot.define do
  factory :media do
    alt { "Test image" }
    position { 0 }

    trait :for_product do
      association :mediaable, factory: :product # rubocop:disable FactoryBot/AssociationStyle
    end

    trait :for_warehouse do
      association :mediaable, factory: :warehouse # rubocop:disable FactoryBot/AssociationStyle
    end

    trait :for_purchase_item do
      association :mediaable, factory: :purchase_item # rubocop:disable FactoryBot/AssociationStyle
    end

    after(:build) do |media|
      media.image.attach(
        io: StringIO.new("test image data"),
        filename: "test.jpg",
        content_type: "image/jpeg"
      )
    end
  end
end
