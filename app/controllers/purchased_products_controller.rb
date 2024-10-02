class PurchasedProductsController < ApplicationController
  before_action :set_purchased_product, only: %i[show edit update destroy]

  # GET /warehouse_products
  def index
    @purchased_products = PurchasedProduct.all
  end

  # GET /purchased_products/1
  def show
  end

  # GET /purchased_products/new
  def new
    @warehouse = Warehouse.find(params[:warehouse_id])
    @purchased_product = PurchasedProduct.new(warehouse: @warehouse)
    @purchases = Purchase.includes(:product, :supplier).order(purchase_date: :desc, created_at: :desc)
  end

  # GET /purchased_products/1/edit
  def edit
    @purchases = Purchase.includes(:product, :supplier).order(purchase_date: :desc, created_at: :desc)
  end

  # POST /warehouse_products
  def create
    @purchased_product = PurchasedProduct.new(purchased_product_params)

    if @purchased_product.save
      redirect_to @purchased_product.warehouse, notice: "Purchased product was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /purchased_products/1
  def update
    if params[:deleted_img_ids].present?
      attachments = ActiveStorage::Attachment.where(id: params[:deleted_img_ids])
    end
    if @purchased_product.update(purchased_product_params)
      attachments&.map(&:purge_later)
      redirect_to @purchased_product, notice: "Purchased product was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /purchased_products/1
  def destroy
    warehouse = @purchased_product.warehouse
    @purchased_product.destroy!

    redirect_to warehouse, notice: "Purchased product was successfully destroyed.", status: :see_other, turbolinks: false
  end

  def move
    ids = params[:selected_items_ids]
    destination_id = params[:destination_id]
    warehouse = Warehouse.find(params[:warehouse_id]) if params[:warehouse_id]
    purchase = Purchase.find(params[:purchase_id]) if params[:purchase_id]

    moved_count = PurchasedProduct.where(id: ids).update_all(warehouse_id: destination_id)

    if moved_count > 0
      destination = Warehouse.find(destination_id)
      flash[:notice] = "Success! #{moved_count} purchased #{"product".pluralize(moved_count)} moved to: #{view_context.link_to(destination.name, warehouse_path(destination))}".html_safe
    end

    if purchase
      redirect_to purchase_path(purchase)
    else
      redirect_to warehouse_path(warehouse)
    end
  end

  private

  def set_purchased_product
    @purchased_product = PurchasedProduct.with_attached_images.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def purchased_product_params
    params.require(:purchased_product).permit(
      :length,
      :width,
      :height,
      :weight,
      :price,
      :shipping_price,
      :warehouse_id,
      :purchase_id,
      deleted_img_ids: [],
      images: []
    )
  end
end
