FactoryBot.define do
  factory :notification do
    name { "Test Notification" }
    status { :active }
    event_type { :warehouse_changed }
  end
end
