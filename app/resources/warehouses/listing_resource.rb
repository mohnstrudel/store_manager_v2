# frozen_string_literal: true

class Warehouses::ListingResource < WarehouseResource
  typelize :string
  attribute :path do |warehouse|
    warehouse_path(warehouse)
  end

  typelize :string
  attribute :edit_path do |warehouse|
    edit_warehouse_path(warehouse)
  end

  typelize :string
  attribute :position_path do |warehouse|
    warehouse_position_path(warehouse)
  end

  attributes :position

  typelize "Array<number>"
  attribute :positions do |_warehouse|
    (1..params.fetch(:warehouses_count)).to_a
  end

  typelize :string
  attribute :external_name_en do |warehouse|
    warehouse.external_name_en.presence || "N/A"
  end

  typelize :string
  attribute :cbm do |warehouse|
    warehouse.cbm.to_s
  end

  typelize :number
  attribute :purchase_items_count do |warehouse|
    warehouse.purchase_items.size
  end

  typelize :boolean
  attribute :has_purchase_items do |warehouse|
    warehouse.purchase_items.any?
  end
end
