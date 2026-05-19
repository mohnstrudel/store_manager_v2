# frozen_string_literal: true

FactoryBot.define do
  factory :sale_address do
    sale
    kind { :shipping }
    first_name { "Robert" }
    last_name { "Dethloff" }
    email { "robert_dethloff@web.de" }
    phone { "017631584891" }
    company { "" }
    address_1 { "Schillerstrasse 68" }
    address_2 { "" }
    city { "Bremerhaven" }
    state { "" }
    postcode { "27570" }
    country { "DE" }
  end
end
