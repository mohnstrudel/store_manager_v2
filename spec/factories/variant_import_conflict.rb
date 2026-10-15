# frozen_string_literal: true

FactoryBot.define do
  factory(:variant_import_conflict) do
    product
    conflicting_variant { association(:variant, product:) }
    sequence(:store_id) { |n| "gid://shopify/ProductVariant/conflict-#{n}" }
    sku { generate(:unique_sku) }
    options { [{"name" => "Version", "value" => "A"}] }
  end
end
