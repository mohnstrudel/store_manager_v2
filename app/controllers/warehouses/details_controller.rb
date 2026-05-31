# frozen_string_literal: true

module Warehouses
  class DetailsController < ApplicationController
    def show
      @warehouse = Warehouse.for_details.find(params[:id])
      @selected_id = params[:selected].presence&.to_i
      @purchase_items = @warehouse
        .purchase_items
        .for_warehouse_details
        .order(updated_at: :desc)
        .page(params[:page])
      @total_purchase_items = @warehouse.purchase_items.size
      @purchase_items = @purchase_items.search(params[:q]) if params[:q].present?

      render inertia: "Warehouses/Show", props: helpers.warehouse_show_props(
        @warehouse,
        purchase_items: @purchase_items,
        search: {q: params[:q].to_s},
        selected_id: @selected_id,
        total_purchase_items: @total_purchase_items
      )
    end

    private

    def authorize_resourse
      authorize :warehouse
    end
  end
end
