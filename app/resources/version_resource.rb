# frozen_string_literal: true

class VersionResource < ApplicationResource
  typelize_from Version

  attributes :id

  typelize :string
  attribute :value do |version|
    version.value.to_s
  end

  typelize :string
  attribute :created_at do |version|
    formatted_timestamp(version.created_at)
  end

  typelize :string
  attribute :updated_at do |version|
    formatted_timestamp(version.updated_at)
  end
end
