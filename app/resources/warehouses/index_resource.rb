# frozen_string_literal: true

class Warehouses::IndexResource < ApplicationResource
  typelize "Array<WarehousesListing>"
  attribute :warehouses do |page|
    warehouses = page.fetch(:warehouses)
    Warehouses::ListingResource.new(warehouses, params: {warehouses_count: warehouses.size}).serializable_hash
  end
end
