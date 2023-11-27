FactoryBot.define do
  factory(:product) do
    franchise
    shape
    full_title { "ToFactory: RubyParser exception parsing this attribute" }
    image { "https://store.handsomecake.com/wp-content/uploads/2023/11/F-z6rD6bYAADn0H-scaled.jpg" }
    store_link { nil }
    title { "Spirited Away" }
    woo_id { "26626" }
  end
end
