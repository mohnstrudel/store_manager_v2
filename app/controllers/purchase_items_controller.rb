# frozen_string_literal: true

class PurchaseItemsController < ApplicationController
  include WarehouseMovementNotification
  include MediaFormHandling

  before_action :set_purchase_item, only: %i[show edit update destroy edit_tracking_number cancel_tracking_number update_tracking_number edit_shipping_company cancel_edit_shipping_company update_shipping_company]

  # GET /warehouse_products
  def index
    @purchase_items = PurchaseItem.all
  end

  # GET /purchase_items/1
  def show
  end

  # GET /purchase_items/new
  def new
    @warehouse = Warehouse.find(params[:warehouse_id])
    @purchase_item = PurchaseItem.new(warehouse: @warehouse)
    load_form_collections
  end

  # GET /purchase_items/1/edit
  def edit
    set_data_for_edit
  end

  # POST /warehouse_products
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
    render :new, status: :unprocessable_content
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
    set_data_for_edit
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

  def move
    ids = params[:selected_items_ids]
    destination_id = params[:destination_id]

    moved_count = PurchaseItem.move_to_warehouse!(
      purchase_item_ids: ids,
      warehouse_id: destination_id
    )

    return if moved_count.zero?

    flash_movement_notice(moved_count, Warehouse.find(destination_id))

    redirect_to_appropriate_path
  end

  def unlink
    purchase_item = PurchaseItem.find(params[:id])
    sale_item = purchase_item.sale_item

    if purchase_item.update(sale_item: nil)
      redirect_to (request.referer || sale_item),
        notice: "Purchase item was successfully unlinked",
        status: :see_other
    else
      redirect_to sale_item,
        alert: "Something went wrong. Try again later or contact the administrators",
        status: :see_other,
        turbolinks: false
    end
  end

  # GET /purchase_items/1/edit_tracking_number
  def edit_tracking_number
    if @purchase_item.shipping_company_id.present?
      render_tracking_number_edit
    else
      render turbo_stream: [
        turbo_replace_purchase_item(:tracking_number, "inline_tracking_edit"),
        turbo_replace_purchase_item(:shipping_company, "inline_shipping_company_edit")
      ]
    end
  end

  # GET /purchase_items/1/cancel_tracking_number
  def cancel_tracking_number
    render turbo_stream: turbo_replace_purchase_item(:tracking_number, "inline_tracking_show")
  end

  # PATCH/PUT /purchase_items/1/update_tracking_number
  def update_tracking_number
    if @purchase_item.update(tracking_number: params[:purchase_item][:tracking_number])
      render turbo_stream: turbo_replace_purchase_item(:tracking_number, "inline_tracking_show")
    else
      render turbo_stream: turbo_replace_purchase_item(:tracking_number, "inline_tracking_edit")
    end
  end

  # GET /purchase_items/1/edit_shipping_company
  def edit_shipping_company
    render turbo_stream: turbo_replace_purchase_item(:shipping_company, "inline_shipping_company_edit")
  end

  # GET /purchase_items/1/cancel_edit_shipping_company
  def cancel_edit_shipping_company
    render turbo_stream: turbo_replace_purchase_item(:shipping_company, "inline_shipping_company_show")
  end

  # PATCH/PUT /purchase_items/1/update_shipping_company
  def update_shipping_company
    if @purchase_item.update(shipping_company_id: params[:purchase_item][:shipping_company_id])
      render turbo_stream: turbo_replace_purchase_item(:shipping_company, "inline_shipping_company_show")
    else
      render turbo_stream: turbo_replace_purchase_item(:shipping_company, "inline_shipping_company_edit")
    end
  end

  private

  def redirect_to_appropriate_path
    redirect_to redirect_target
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

  def set_purchase_item
    @purchase_item = PurchaseItem.with_media.find(params[:id])
  end

  def set_data_for_edit
    @sale_items = SaleItem.for_edit_linking(@purchase_item)
    load_form_collections
  end

  def load_form_collections
    @purchases = Purchase.for_form_select
    @shipping_companies = ShippingCompany.order(:name)
    @warehouse_options = Warehouse.order(:name)
  end

  def render_tracking_number_edit
    render turbo_stream: turbo_replace_purchase_item(:tracking_number, "inline_tracking_edit")
  end

  def turbo_replace_purchase_item(field, partial)
    turbo_stream.replace(
      helpers.dom_id(@purchase_item, field),
      partial:,
      locals: {purchase_item: @purchase_item}
    )
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
