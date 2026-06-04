# frozen_string_literal: true

FactoryBot.define do
  factory :warehouse_transition do
    notification
    from_warehouse factory: %i[warehouse]
    to_warehouse factory: %i[warehouse]
  end
end
