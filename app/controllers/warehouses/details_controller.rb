# frozen_string_literal: true

module Warehouses
  class DetailsController < ApplicationController
    def show
      @warehouse = Warehouse.preloaded.find(params.expect(:id))
      @selected_id = params[:selected].presence&.to_i
      @purchase_items = @warehouse
        .purchase_items
        .preloaded_for_warehouse
        .ordered_by_current_warehouse_entry
        .page(params[:page])
      @total_purchase_items = @warehouse.purchase_items.size
      @purchase_items = @purchase_items.search(params[:q]) if params[:q].present?

      render_inertia "Warehouses/Show", serializer: Warehouses::ShowResource,
        locals: {
          warehouse: @warehouse,
          purchase_items: @purchase_items,
          query: params[:q].to_s,
          selected_id: @selected_id,
          total_purchase_items: @total_purchase_items
        }
    end

    private

    def authorize_resource
      authorize :warehouse
    end
  end
end
