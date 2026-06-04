# frozen_string_literal: true

module Warehouses
  class ItemsController < ApplicationController
    include MediaFormHandling
    include WarehouseScoped

    def new
      @purchase_item = PurchaseItem.new(warehouse: @warehouse)
      render inertia: "PurchaseItems/New",
        props: helpers.purchase_item_new_props(@purchase_item, warehouse: @warehouse)
    end

    def create
      @purchase_item = PurchaseItem.new

      @purchase_item.create_from_form!(
        purchase_item_params.to_h,
        new_media_images: media_new_images_for(@purchase_item)
      )

      redirect_to @purchase_item.warehouse,
        notice: "Purchase item was successfully created"
    rescue ActiveRecord::RecordInvalid
      redirect_to new_warehouse_item_path(@warehouse),
        inertia: inertia_errors(@purchase_item.errors)
    end

    private

    def authorize_resource
      authorize :purchase_item
    end

    def purchase_item_params
      params.expect(
        purchase_item: [:length,
          :width,
          :height,
          :weight,
          :expenses,
          :shipping_cost,
          :tracking_number,
          :warehouse_id,
          :purchase_id,
          :sale_item_id,
          :redirect_to_sale_item,
          :shipping_company_id]
      )
    end
  end
end
