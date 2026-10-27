# frozen_string_literal: true

FactoryBot.define do
  factory :sales_tag do
    sequence(:name) { |n| "Tag#{n}" }
    color { "gray" }
  end
end
