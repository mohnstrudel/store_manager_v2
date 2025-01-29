FactoryBot.define do
  factory :warehouse_transition do
    association :notification
    association :from_warehouse, factory: :warehouse
    association :to_warehouse, factory: :warehouse
  end
end
