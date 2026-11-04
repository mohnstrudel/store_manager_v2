# frozen_string_literal: true

class Sales::FormItemResource < ApplicationResource
  typelize_from SaleItem

  typelize id: "number | null", product_id: "number | null", variant_id: "number | null"
  attributes :id, :product_id, :variant_id

  typelize :string
  attribute :qty do |item|
    item.qty.to_s
  end

  typelize :string
  attribute :price do |item|
    item.price.to_s
  end

  typelize :boolean
  attribute :_destroy do |_item|
    false
  end

  typelize "VariantAvailability", nullable: true
  attribute :variant_availability do |item|
    VariantAvailabilityResource.new(item.product, params: {current_variant: item.variant}).serializable_hash if item.product
  end
end
