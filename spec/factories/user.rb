FactoryBot.define do
  factory(:user) do
    sequence(:email_address) { |n| "ivan148#{n}@mail.com" }
    first_name { "Ivan" }
    last_name { "Miller" }
    role { :guest }
    password { "password" }

    trait :admin do
      role { :admin }
    end

    trait :manager do
      role { :manager }
    end

    trait :support do
      role { :support }
    end
  end
end
