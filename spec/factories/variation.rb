FactoryBot.define do
  factory(:variation) do
    product
    store_link { "https://store.handsomecake.com/link-id?variation=666" }
    woo_id { "666" }
  end
end
