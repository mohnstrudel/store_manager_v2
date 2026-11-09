# frozen_string_literal: true

class SupplierResource < ApplicationResource
  typelize_from Supplier

  attributes :id

  typelize :string
  attribute :title do |supplier|
    supplier.title.to_s
  end

  typelize :string
  attribute :created_at do |supplier|
    formatted_timestamp(supplier.created_at)
  end

  typelize :string
  attribute :updated_at do |supplier|
    formatted_timestamp(supplier.updated_at)
  end
end
