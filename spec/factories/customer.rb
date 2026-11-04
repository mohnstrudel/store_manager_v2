# frozen_string_literal: true

FactoryBot.define do
  factory(:customer) do
    transient do
      woo_store_id { nil }
      synced { false }
    end

    email { "italy_mp@web.de" }
    first_name { "Michele" }
    last_name { "Pomarico" }
    phone { "+491729364665" }
    woo_id { SecureRandom.alphanumeric(10) }

    after(:create) do |customer, evaluator|
      if evaluator.synced || evaluator.woo_store_id
        customer.upsert_woo_info(store_id: evaluator.woo_store_id || customer[:woo_id])
      end
    end

    trait :synced do
      synced { true }
    end
  end
end
