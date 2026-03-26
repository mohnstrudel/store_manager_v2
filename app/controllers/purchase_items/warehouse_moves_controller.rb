# frozen_string_literal: true

module PurchaseItems
  class WarehouseMovesController < ApplicationController
    include WarehouseMovementNotification

    def create
      moved_count = PurchaseItem.move_to_warehouse!(
        purchase_item_ids: params[:selected_items_ids],
        warehouse_id: params[:destination_id]
      )

      return if moved_count.zero?

      flash_movement_notice(moved_count, Warehouse.find(params[:destination_id]))
      redirect_to redirect_target
    end

    private

    def authorize_resourse
      authorize :purchase_item, :move?
    end

    def redirect_target
      return purchase_path(params[:purchase_id]) if params[:purchase_id].present?
      return selected_sale_item if redirect_to_sale_item?

      warehouse_path(params[:warehouse_id])
    end

    def redirect_to_sale_item?
      params[:redirect_to_sale_item].present? && selected_item_ids.any?
    end

    def selected_item_ids
      Array(params[:selected_items_ids]).compact_blank
    end

    def selected_sale_item
      purchase_item = PurchaseItem.find_by(id: selected_item_ids.first)
      purchase_item&.sale_item || warehouse_path(params[:warehouse_id])
    end
  end
end
