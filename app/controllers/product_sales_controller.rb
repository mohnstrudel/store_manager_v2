class ProductSalesController < ApplicationController
  before_action :set_product_sale, only: %i[show edit update destroy]

  # GET /product_sales/1
  def show
  end

  # GET /product_sales/1/edit
  def edit
    @purchases = Purchase.includes(:product, :supplier).order(purchase_date: :desc, created_at: :desc)
  end

  # PATCH/PUT /product_sales/1
  def update
    if params[:deleted_img_ids].present?
      attachments = ActiveStorage::Attachment.where(id: params[:deleted_img_ids])
    end

    if @product_sale.update(product_sale_params)
      attachments&.map(&:purge_later)
      redirect_to @product_sale, notice: "Purchased product was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /product_sales/1
  def destroy
    warehouse = @product_sale.warehouse
    @product_sale.destroy!

    redirect_to warehouse, notice: "Purchased product was successfully destroyed.", status: :see_other, turbolinks: false
  end

  private

  def set_product_sale
    @product_sale = ProductSale.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def product_sale_params
    params.require(:product_sale).permit(
      :price,
      :qty,
      :sale_id,
      :variation_id,
      :woo_id
    )
  end
end
