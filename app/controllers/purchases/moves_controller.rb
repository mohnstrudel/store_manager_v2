# frozen_string_literal: true

module Purchases
  class MovesController < ApplicationController
    include WarehouseMovementNotification

    def create
      moved_count = Purchase.friendly
        .where(id: purchase_ids_for_movement)
        .sum { |purchase| purchase.move_to_warehouse!(params[:destination_id]) }

      flash_movement_notice(moved_count, Warehouse.find(params[:destination_id]))
      redirect_after_purchase_move
    end

    private

    def authorize_resourse
      authorize :purchase, :move?
    end

    def purchase_ids_for_movement
      params[:selected_items_ids].presence || params[:purchase_id]
    end

    def redirect_after_purchase_move
      if params[:purchase_id].present?
        redirect_to purchase_path(Purchase.friendly.find(params[:purchase_id]))
      else
        redirect_to purchases_path
      end
    end
  end
end
