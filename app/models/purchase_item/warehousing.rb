# frozen_string_literal: true

module PurchaseItem::Warehousing
  extend ActiveSupport::Concern

  NOTHING_MOVED = 0
  WarehouseMovement = Data.define(:moved_in, :warehouse)

  class_methods do
    def move_to_warehouse!(purchase_item_ids:, warehouse_id:)
      warehouse_id = warehouse_id.to_i
      purchase_items = where(id: purchase_item_ids).to_a
      return NOTHING_MOVED if purchase_items.blank?

      purchase_item_ids_by_origin = purchase_items
        .group_by(&:warehouse_id)
        .transform_values { |items| items.pluck(:id) }

      purchase_items.each do |purchase_item|
        purchase_item.move_to_warehouse!(warehouse_id)
      end

      purchase_item_ids_by_origin.each do |from_id, ids|
        PurchaseItem.notify_order_status_change!(
          purchase_item_ids: ids,
          from_id:,
          to_id: warehouse_id
        )
      end

      purchase_items.size
    end
  end

  def move_to_warehouse!(warehouse_id)
    update!(warehouse_id:)
  end

  def warehouse_movements
    movement_data = audits.each_with_object([]) do |audit, rows|
      moved_warehouse_id = moved_warehouse_id_for(audit)
      next if moved_warehouse_id.blank?

      rows << {moved_in: audit.created_at, warehouse_id: moved_warehouse_id}
    end

    warehouses_by_id = Warehouse
      .where(id: movement_data.pluck(:warehouse_id))
      .index_by(&:id)

    movement_data.map do |movement|
      WarehouseMovement.new(
        moved_in: movement[:moved_in],
        warehouse: warehouses_by_id[movement[:warehouse_id]]
      )
    end
  end

  private

  def moved_warehouse_id_for(audit)
    change = audit.audited_changes["warehouse_id"]
    value = change.is_a?(Array) ? change.last : change
    value&.to_i
  end
end
