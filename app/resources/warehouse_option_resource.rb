# frozen_string_literal: true

class WarehouseOptionResource < ApplicationResource
  typelize_from Warehouse

  attributes :id

  typelize :string
  attribute :name, &:name
end
