# frozen_string_literal: true

# == Schema Information
#
# Table name: media
#
#  id             :bigint           not null, primary key
#  alt            :string           default(""), not null
#  mediaable_type :string           not null
#  position       :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  mediaable_id   :bigint           not null
#
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
