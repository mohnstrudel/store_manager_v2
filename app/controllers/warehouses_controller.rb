class WarehousesController < ApplicationController
  before_action :set_warehouse, only: %i[show edit update destroy]
  before_action :validate_default_warehouse, only: %i[create update]

  # GET /warehouses
  def index
    @warehouses = Warehouse.all.with_attached_images.includes(:purchased_products).order(:position)
  end

  # GET /warehouses/1
  def show
    @purchased_products = @warehouse
      .purchased_products
      .with_attached_images
      .includes(:product, sale: :customer)
      .order(updated_at: :desc)
      .page(params[:page])
    @total_purchased_products = @warehouse.purchased_products.size
    @purchased_products = @purchased_products.search(params[:q]) if params[:q].present?
  end

  # GET /warehouses/new
  def new
    @warehouse = Warehouse.new
    @positions_count = Warehouse.count + 1
  end

  # GET /warehouses/1/edit
  def edit
    @positions_count = Warehouse.count
  end

  # POST /warehouses
  def create
    @warehouse = Warehouse.new(warehouse_params)

    if @warehouse.save
      if @warehouse.is_default?
        Warehouse.ensure_only_one_default(@warehouse.id)
      end

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

    ActiveRecord::Base.transaction do
      if @warehouse.update(warehouse_params)
        attachments&.map(&:purge_later)

        if @warehouse.is_default?
          Warehouse.ensure_only_one_default(@warehouse.id)
        end

        if params[:warehouse][:to_warehouse_ids].present?
          WarehouseTransition
            .where(from_warehouse: @warehouse)
            .where.not(to_warehouse_id: params[:warehouse][:to_warehouse_ids])
            .destroy_all

          params[:warehouse][:to_warehouse_ids].each do |to_id|
            next if to_id.blank?

            notification = Notification.find_or_create_by!(
              name: "Warehouse transition",
              event_type: Notification.event_types[:warehouse_changed],
              status: :active
            )

            WarehouseTransition.find_or_create_by!(
              from_warehouse: @warehouse,
              to_warehouse_id: to_id,
              notification: notification
            )
          end
        end

        redirect_to @warehouse, notice: "Warehouse was successfully updated.", status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
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

  def change_position
    new_position = params[:position].to_i

    return head :bad_request unless new_position.positive?

    warehouse = Warehouse.find(params[:id])

    prev_position = warehouse.position

    if warehouse.update(position: new_position)
      respond_to do |format|
        format.html { redirect_to warehouses_url, notice: "We changed \"#{warehouse.name}\" position from #{prev_position} to #{new_position}.", status: :see_other }
        format.json { head :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to warehouses_url, alert: "Failed to update position.", status: :unprocessable_entity }
        format.json { head :unprocessable_entity }
      end
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
      :position,
      deleted_img_ids: [],
      images: []
    )
  end

  def validate_default_warehouse
    if warehouse_params[:is_default] == "1"
      current_default = Warehouse.find_by(is_default: true)

      if current_default && current_default != @warehouse
        error_message = "change the current default warehouse \"#{view_context.link_to(current_default.name, warehouse_path(current_default))}\" before setting a new one".html_safe

        @warehouse.errors.add(:is_default, error_message)
        @positions_count = Warehouse.count
        render :edit, status: :unprocessable_entity
      end
    end
  end
end
