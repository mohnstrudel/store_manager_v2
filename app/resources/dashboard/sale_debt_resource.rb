# frozen_string_literal: true

class Dashboard::SaleDebtResource < ApplicationResource
  typelize_from Product

  attributes :id

  typelize :string
  attribute :path do |product|
    product_path(product.slug)
  end

  typelize :number
  attribute :row_id do |product|
    product.sale_variant_id || product.id
  end

  typelize :string, nullable: true
  attribute :title, &:full_title

  typelize :string, nullable: true
  attribute :variant_name do |product|
    product.variant_name if product.sale_variant_id.present?
  end

  typelize :number
  attribute :debt do |product|
    product.debt.to_i
  end
end
