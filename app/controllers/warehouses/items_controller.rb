# frozen_string_literal: true

module Warehouses
  class ItemsController < ApplicationController
    include MediaFormHandling
    include WarehouseScoped

    def new
      @purchase_item = PurchaseItem.new(warehouse: @warehouse)
      load_form_collections

      render "purchase_items/new"
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
      load_form_collections
      render "purchase_items/new", status: :unprocessable_content
    end

    private

    def authorize_resourse
      authorize :purchase_item
    end

    def load_form_collections
      @purchases = Purchase.for_form_select
      @shipping_companies = ShippingCompany.order(:name)
      @warehouse_options = Warehouse.order(:name)
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
