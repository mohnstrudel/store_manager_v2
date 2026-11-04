# frozen_string_literal: true

class Warehouses::FormResource < ApplicationResource
  typelize({
    id: "number | null",
    path: :string,
    name: "string | null",
    external_name_en: "string | null",
    external_name_de: "string | null",
    desc_en: "string | null",
    desc_de: "string | null",
    cbm: :string,
    container_tracking_number: "string | null",
    courier_tracking_url: "string | null",
    is_default: :boolean,
    position: :number,
    media: "Array<MediaForm>",
    transition_ids: "Array<number>"
  })
  attribute :warehouse do |page|
    warehouse = page.fetch(:warehouse)

    {
      id: warehouse.id,
      path: warehouse.persisted? ? warehouse_path(warehouse) : "",
      name: warehouse.name,
      external_name_en: warehouse.external_name_en,
      external_name_de: warehouse.external_name_de,
      desc_en: warehouse.desc_en,
      desc_de: warehouse.desc_de,
      cbm: warehouse.cbm.to_s,
      container_tracking_number: warehouse.container_tracking_number,
      courier_tracking_url: warehouse.courier_tracking_url,
      is_default: warehouse.is_default?,
      position: warehouse.position,
      media: MediaFormResource.attached(warehouse.media),
      transition_ids: warehouse.from_transitions.map(&:to_warehouse_id)
    }
  end

  typelize({positions: "Array<number>", transition_destinations: "Array<WarehouseOption>"})
  attribute :options do |page|
    warehouse = page.fetch(:warehouse)

    {
      positions: (1..page.fetch(:positions_count)).to_a,
      transition_destinations: WarehouseOptionResource.new(Warehouse.where.not(id: warehouse.id).order(:name)).serializable_hash
    }
  end
end
