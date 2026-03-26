# frozen_string_literal: true

class PurchaseItemsController < ApplicationController
  include MediaFormHandling

  before_action :set_purchase_item, only: %i[show edit update destroy]

  # GET /warehouse_products
  def index
    @purchase_items = PurchaseItem.all
  end

  # GET /purchase_items/1
  def show
  end

  # GET /purchase_items/1/edit
  def edit
    prepare_edit_form
  end

  # PATCH/PUT /purchase_items/1
  def update
    @purchase_item.apply_form_changes!(
      attributes: purchase_item_params.except(:redirect_to_sale_item).to_h,
      media_attributes: normalized_media_attributes_for(@purchase_item),
      new_media_images: media_new_images_for(@purchase_item)
    )

    path = purchase_item_params[:redirect_to_sale_item] ?
      @purchase_item.sale_item :
      @purchase_item

    redirect_to path, notice: "Purchase item was successfully updated", status: :see_other
  rescue ActiveRecord::RecordInvalid
    prepare_edit_form
    render :edit, status: :unprocessable_content
  end

  # DELETE /purchase_items/1
  def destroy
    warehouse = @purchase_item.warehouse
    @purchase_item.destroy!

    redirect_to warehouse,
      notice: "Purchase item was successfully destroyed",
      status: :see_other,
      turbolinks: false
  end

  private

  def set_purchase_item
    @purchase_item = PurchaseItem.with_media.find(params[:id])
  end

  def prepare_edit_form
    @sale_items = SaleItem.for_edit_linking(@purchase_item)
    prepare_form_options
  end

  def prepare_form_options
    @purchases = Purchase.for_form_select
    @shipping_companies = ShippingCompany.order(:name)
    @warehouse_options = Warehouse.order(:name)
  end

  # Only allow a list of trusted parameters through.
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
