# frozen_string_literal: true

class Products::FormVariantResource < ApplicationResource
  typelize_from Variant

  typelize :number, nullable: true
  attribute :id, &:id

  typelize :boolean
  attribute :base_model, &:base_model?

  attributes :sku, :size_id, :version_id, :color_id

  typelize :string
  attribute :purchase_cost do |variant|
    variant.purchase_cost.to_s
  end

  typelize :string
  attribute :selling_price do |variant|
    variant.selling_price.to_s
  end

  typelize :string
  attribute :weight do |variant|
    variant.weight.to_s
  end

  typelize :boolean
  attribute :deactivated, &:deactivated?

  typelize :boolean
  attribute :has_sales_or_purchases do |variant|
    variant.persisted? && variant.has_sales_or_purchases?
  end

  typelize :boolean
  attribute :_destroy do |_variant|
    false
  end
end
