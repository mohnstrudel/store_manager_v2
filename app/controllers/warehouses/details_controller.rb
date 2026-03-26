# frozen_string_literal: true

module Warehouses
  class DetailsController < ApplicationController
    def show
      @warehouse = Warehouse.for_details.find(params[:id])
      @purchase_items = @warehouse
        .purchase_items
        .for_warehouse_details
        .order(updated_at: :desc)
        .page(params[:page])
      @total_purchase_items = @warehouse.purchase_items.size
      @purchase_items = @purchase_items.search(params[:q]) if params[:q].present?

      render "warehouses/show"
    end

    private

    def authorize_resourse
      authorize :warehouse
    end
  end
end
