# frozen_string_literal: true

class Warehouses::DetailResource < WarehouseResource
  typelize :string
  attribute :edit_path do |warehouse|
    edit_warehouse_path(warehouse)
  end

  typelize :string
  attribute :destroy_path do |warehouse|
    warehouse_path(warehouse)
  end

  typelize :string
  attribute :new_item_path do |warehouse|
    new_warehouse_item_path(warehouse)
  end

  typelize :string, nullable: true
  attribute :external_name_en do |warehouse|
    safe_blank_render(warehouse.external_name_en)
  end

  typelize :string, nullable: true
  attribute :desc_en do |warehouse|
    safe_blank_render(warehouse.desc_en)
  end

  typelize :string, nullable: true
  attribute :external_name_de do |warehouse|
    safe_blank_render(warehouse.external_name_de)
  end

  typelize :string, nullable: true
  attribute :desc_de do |warehouse|
    safe_blank_render(warehouse.desc_de)
  end

  typelize :string, nullable: true
  attribute :cbm do |warehouse|
    safe_blank_render(warehouse.cbm)
  end

  typelize :string, nullable: true
  attribute :container_tracking_number do |warehouse|
    safe_blank_render(warehouse.container_tracking_number)
  end

  attributes :courier_tracking_url

  typelize :string
  attribute :created_at do |warehouse|
    format_date(warehouse.created_at)
  end

  typelize "Array<Media>"
  attribute :media do |warehouse|
    MediaResource.attached(warehouse.media)
  end
end
