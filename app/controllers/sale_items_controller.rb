class SaleItemsController < ApplicationController
  before_action :set_sale_item, only: %i[show edit update destroy]

  # GET /sale_items/1
  def show
    @sale_item = SaleItem.includes(purchase_items: :warehouse).find(params[:id])
  end

  # GET /sale_items/1/edit
  def edit
    @purchases = Purchase.includes(:product, :supplier).order(purchase_date: :desc, created_at: :desc)
  end

  # PATCH/PUT /sale_items/1
  def update
    if params[:deleted_img_ids].present?
      attachments = ActiveStorage::Attachment.where(id: params[:deleted_img_ids])
    end

    if @sale_item.update(sale_item_params)
      attachments&.map(&:purge_later)
      redirect_to @sale_item, notice: "Sale item was successfully updated", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /sale_items/1
  def destroy
    warehouse = @sale_item.warehouse
    @sale_item.destroy!

    redirect_to warehouse, notice: "Sale item was successfully destroyed", status: :see_other, turbolinks: false
  end

  private

  def set_sale_item
    @sale_item = SaleItem.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def sale_item_params
    params.expect(
      sale_item: [:price,
        :qty,
        :sale_id,
        :edition_id,
        :woo_id]
    )
  end
end
