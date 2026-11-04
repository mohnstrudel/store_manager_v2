# frozen_string_literal: true

class ColorResource < ApplicationResource
  typelize_from Color

  attributes :id

  typelize :string
  attribute :value do |color|
    color.value.to_s
  end

  typelize :string
  attribute :created_at do |color|
    formatted_timestamp(color.created_at)
  end

  typelize :string
  attribute :updated_at do |color|
    formatted_timestamp(color.updated_at)
  end
end
