class PurchaseItemsController < ApplicationController
  include WarehouseMovementNotification

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
    @purchases = Purchase
      .includes(:product, :supplier)
      .order(purchase_date: :desc, created_at: :desc)
    @shipping_companies = ShippingCompany.all
  end

  # GET /purchase_items/1/edit
  def edit
    set_data_for_edit
  end

  # POST /warehouse_products
  def create
    @purchase_item = PurchaseItem.new(purchase_item_params)

    if @purchase_item.save
      redirect_to @purchase_item.warehouse,
        notice: "Purchase item was successfully created"
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /purchase_items/1
  def update
    if params[:deleted_img_ids].present?
      deleted_imgs = ActiveStorage::Attachment.where(id: params[:deleted_img_ids])
    end

    if @purchase_item.update(
      purchase_item_params.except(:redirect_to_sale_item)
    )
      path = purchase_item_params[:redirect_to_sale_item] ?
        @purchase_item.sale_item :
        @purchase_item

      deleted_imgs&.map(&:purge_later)

      redirect_to path, notice: "Purchase item was successfully updated", status: :see_other
    else
      set_data_for_edit
      render :edit, status: :unprocessable_content
    end
  end

  # GET /purchase_items/1/edit_tracking_number
  def edit_tracking_number
    respond_to do |format|
      format.html { head :no_content }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          helpers.dom_id(@purchase_item, :tracking_number),
          partial: "inline_tracking_edit",
          locals: {purchase_item: @purchase_item}
        )
      }
    end
  end

  # GET /purchase_items/1/cancel_tracking_number
  def cancel_tracking_number
    respond_to do |format|
      format.html { head :no_content }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          helpers.dom_id(@purchase_item, :tracking_number),
          partial: "inline_tracking_show",
          locals: {purchase_item: @purchase_item}
        )
      }
    end
  end

  # PATCH/PUT /purchase_items/1/update_tracking_number
  def update_tracking_number
    if @purchase_item.update(tracking_number: params[:purchase_item][:tracking_number])
      render turbo_stream: [
        turbo_stream.replace(
          helpers.dom_id(@purchase_item, :tracking_number),
          partial: "inline_tracking_show",
          locals: {purchase_item: @purchase_item}
        ),
        turbo_stream.update(
          helpers.dom_id(@purchase_item, :highlight_tracking_number),
          partial: "shared/td_highlight",
          locals: {cell_id: helpers.dom_id(@purchase_item, :highlight_tracking_number)}
        )
      ]
    else
      render turbo_stream: turbo_stream.replace(
        helpers.dom_id(@purchase_item, :tracking_number),
        partial: "inline_tracking_edit",
        locals: {purchase_item: @purchase_item}
      )
    end
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

    moved_count = ProductMover.move(
      warehouse_id: destination_id,
      purchase_items_ids: ids
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

  # GET /purchase_items/1/edit_shipping_company
  def edit_shipping_company
    respond_to do |format|
      format.html { head :no_content }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          helpers.dom_id(@purchase_item, :shipping_company),
          partial: "inline_shipping_company_edit",
          locals: {purchase_item: @purchase_item}
        )
      }
    end
  end

  # GET /purchase_items/1/cancel_edit_shipping_company
  def cancel_edit_shipping_company
    respond_to do |format|
      format.html { head :no_content }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          helpers.dom_id(@purchase_item, :shipping_company),
          partial: "inline_shipping_company_show",
          locals: {purchase_item: @purchase_item}
        )
      }
    end
  end

  # PATCH/PUT /purchase_items/1/update_shipping_company
  def update_shipping_company
    if @purchase_item.update(shipping_company_id: params[:purchase_item][:shipping_company_id])
      render turbo_stream: [
        turbo_stream.replace(
          helpers.dom_id(@purchase_item, :shipping_company),
          partial: "inline_shipping_company_show",
          locals: {purchase_item: @purchase_item}
        ),
        turbo_stream.update(
          helpers.dom_id(@purchase_item, :highlight_shipping_company),
          partial: "shared/td_highlight",
          locals: {cell_id: helpers.dom_id(@purchase_item, :highlight_shipping_company)}
        )
      ]
    else
      render turbo_stream: turbo_stream.replace(
        helpers.dom_id(@purchase_item, :shipping_company),
        partial: "inline_shipping_company_edit",
        locals: {purchase_item: @purchase_item}
      )
    end
  end

  private

  def redirect_to_appropriate_path
    if params[:purchase_id].present?
      redirect_to purchase_path(params[:purchase_id])
    elsif params[:redirect_to_sale_item] && params[:selected_items_ids].present?
      sale_item = PurchaseItem
        .find(params[:selected_items_ids].first)
        .sale_item
      redirect_to sale_item
    else
      redirect_to warehouse_path(params[:warehouse_id])
    end
  end

  def set_purchase_item
    @purchase_item = PurchaseItem.with_attached_images.find(params[:id])
  end

  def set_data_for_edit
    all_sale_items = SaleItem.includes(
      :product,
      sale: [:customer],
      edition: [:color, :size, :version]
    ).where(
      sales: {status: Sale.active_status_names + Sale.completed_status_names}
    )
    @sale_items = all_sale_items.where(
      product_id: @purchase_item.product
    ) + all_sale_items.where.not(
      product_id: @purchase_item.product
    )
    @purchases = Purchase.includes(:product, :supplier).order(
      purchase_date: :desc,
      created_at: :desc
    )
    @shipping_companies = ShippingCompany.all
  end

  # Only allow a list of trusted parameters through.
  def purchase_item_params
    params.require(:purchase_item).permit(
      :length,
      :width,
      :height,
      :weight,
      :expenses,
      :shipping_price,
      :tracking_number,
      :warehouse_id,
      :purchase_id,
      :sale_item_id,
      :redirect_to_sale_item,
      :shipping_company_id,
      deleted_img_ids: [],
      images: []
    )
  end
end
