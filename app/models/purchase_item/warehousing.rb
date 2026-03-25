# frozen_string_literal: true

module PurchaseItem::Warehousing
  extend ActiveSupport::Concern

  NOTHING_MOVED = 0

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
end
