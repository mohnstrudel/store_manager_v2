# frozen_string_literal: true

class SizeResource < ApplicationResource
  typelize_from Size

  attributes :id

  typelize :string
  attribute :value do |size|
    size.value.to_s
  end

  typelize :string
  attribute :created_at do |size|
    formatted_timestamp(size.created_at)
  end

  typelize :string
  attribute :updated_at do |size|
    formatted_timestamp(size.updated_at)
  end
end
