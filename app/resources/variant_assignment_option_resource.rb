# frozen_string_literal: true

class VariantAssignmentOptionResource < ApplicationResource
  typelize_from Variant

  typelize :number
  attribute :value, &:id

  typelize :string
  attribute :label do |variant|
    variant.title.to_s
  end

  typelize :boolean
  attribute :base_model, &:base_model?
end
