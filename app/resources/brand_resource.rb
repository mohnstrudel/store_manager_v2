# frozen_string_literal: true

class BrandResource < ApplicationResource
  typelize_from Brand

  attributes :id

  typelize :string
  attribute :title do |brand|
    brand.title.to_s
  end

  typelize :string
  attribute :created_at do |brand|
    formatted_timestamp(brand.created_at)
  end

  typelize :string
  attribute :updated_at do |brand|
    formatted_timestamp(brand.updated_at)
  end
end
