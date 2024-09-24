class WarehousesController < ApplicationController
  before_action :set_warehouse, only: %i[show edit update destroy]

  # GET /warehouses
  def index
    @warehouses = Warehouse.all.with_attached_images.includes(:purchased_products).order(updated_at: :desc)
  end

  # GET /warehouses/1
  def show
    @purchased_products = @warehouse
      .purchased_products
      .with_attached_images
      .includes(:product)
      .order(updated_at: :desc)
      .page(params[:page])
    @total_purchased_products = @warehouse.purchased_products.size
    @purchased_products = @purchased_products.search(params[:q]) if params[:q].present?
  end

  # GET /warehouses/new
  def new
    @warehouse = Warehouse.new
  end

  # GET /warehouses/1/edit
  def edit
  end

  # POST /warehouses
  def create
    @warehouse = Warehouse.new(warehouse_params)

    if @warehouse.save
      redirect_to @warehouse, notice: "Warehouse was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /warehouses/1
  def update
    if params[:deleted_img_ids].present?
      attachments = ActiveStorage::Attachment.where(id: params[:deleted_img_ids])
    end
    if @warehouse.update(warehouse_params)
      attachments&.map(&:purge_later)
      redirect_to @warehouse, notice: "Warehouse was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /warehouses/1
  def destroy
    warehouse_name = @warehouse.name

    if @warehouse.purchased_products.any?
      flash[:error] = "Error. Please select and move out all purchased products before deleting the warehouse."
      redirect_to @warehouse
    else
      @warehouse.destroy!
      redirect_to warehouses_url, notice: "Warehouse #{warehouse_name} was successfully destroyed.", status: :see_other
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_warehouse
    @warehouse = Warehouse.with_attached_images.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def warehouse_params
    params.require(:warehouse).permit(
      :cbm,
      :container_tracking_number,
      :courier_tracking_url,
      :external_name,
      :name,
      :is_default,
      deleted_img_ids: [],
      images: []
    )
  end
end
