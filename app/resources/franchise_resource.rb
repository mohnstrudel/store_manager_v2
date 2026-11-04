# frozen_string_literal: true

class FranchiseResource < ApplicationResource
  typelize_from Franchise

  attributes :id

  typelize :string
  attribute :title do |franchise|
    franchise.title.to_s
  end

  typelize :string
  attribute :created_at do |franchise|
    formatted_timestamp(franchise.created_at)
  end

  typelize :string
  attribute :updated_at do |franchise|
    formatted_timestamp(franchise.updated_at)
  end
end
