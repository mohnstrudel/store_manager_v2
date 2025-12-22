# frozen_string_literal: true
FactoryBot.define do
  factory(:customer) do
    email { "italy_mp@web.de" }
    first_name { "Michele" }
    last_name { "Pomarico" }
    phone { "+491729364665" }
    woo_id { SecureRandom.alphanumeric(10) }
  end
end
