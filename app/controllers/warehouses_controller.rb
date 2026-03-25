# frozen_string_literal: true

class WarehousesController < ApplicationController
  include ActionView::Helpers::OutputSafetyHelper
  include MediaFormHandling

  before_action :set_warehouse, only: %i[edit update destroy]
  before_action :validate_default_warehouse, only: %i[update]

  # GET /warehouses
  def index
    @warehouses = Warehouse.for_listing.order(:position)
  end

  # GET /warehouses/1
  def show
    @warehouse = Warehouse.for_details.find(params[:id])
    @purchase_items = @warehouse
      .purchase_items
      .for_warehouse_details
      .order(updated_at: :desc)
      .page(params[:page])
    @total_purchase_items = @warehouse.purchase_items.size
    @purchase_items = @purchase_items.search(params[:q]) if params[:q].present?
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
    return render_default_warehouse_conflict! if default_warehouse_conflict?(@warehouse)

    if @warehouse.save
      @warehouse.add_new_media_from_form!(media_new_images_for(@warehouse))
      Warehouse.ensure_only_one_default(@warehouse.id) if @warehouse.is_default?

      redirect_to @warehouse, notice: "Warehouse was successfully created"
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /warehouses/1
  def update
    result = Warehouse::UpdateWorkflow.call(
      warehouse: @warehouse,
      attributes: warehouse_update_attributes,
      transition_ids: params.dig(:warehouse, :to_warehouse_ids),
      after_update: -> {
        @warehouse.update_media_from_form!(normalized_media_attributes_for(@warehouse))
        @warehouse.add_new_media_from_form!(media_new_images_for(@warehouse))
      }
    )

    if result == Warehouse::UpdateWorkflow::TRANSITIONS_UPDATED
      redirect_to @warehouse, notice: "Warehouse transitions were successfully updated", status: :see_other
    else
      redirect_to @warehouse, notice: "Warehouse was successfully updated", status: :see_other
    end
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_content
  end

  # DELETE /warehouses/1
  def destroy
    warehouse_name = @warehouse.name

    if @warehouse.purchase_items.any?
      flash[:error] = "Error. Please select and move out all purchased products before deleting the warehouse"
      redirect_to @warehouse
    else
      @warehouse.destroy!
      redirect_to warehouses_url, notice: "Warehouse #{warehouse_name} was successfully destroyed", status: :see_other
    end
  end

  def change_position
    new_position = params[:position].to_i

    return head :bad_request unless new_position.positive?

    warehouse = Warehouse.find(params[:id])

    prev_position = warehouse.position

    if warehouse.update(position: new_position)
      respond_to do |format|
        format.html { redirect_to warehouses_url, notice: "We changed \"#{warehouse.name}\" position from #{prev_position} to #{new_position}", status: :see_other }
        format.json { head :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to warehouses_url, alert: "Failed to update position", status: :unprocessable_content }
        format.json { head :unprocessable_content }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_warehouse
    @warehouse = Warehouse.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def warehouse_params
    params.expect(
      warehouse: [:cbm,
        :container_tracking_number,
        :courier_tracking_url,
        :external_name_en,
        :external_name_de,
        :desc_en,
        :desc_de,
        :name,
        :is_default,
        :position,
        :to_warehouse_ids]
    )
  end

  def warehouse_update_attributes
    return {"to_warehouse_ids" => params.dig(:warehouse, :to_warehouse_ids)} if transition_only_update?

    warehouse_params.to_h
  end

  def transition_only_update?
    params[:warehouse].present? && params[:warehouse].keys.map(&:to_sym) == [:to_warehouse_ids]
  end

  def validate_default_warehouse
    return unless default_warehouse_conflict?(@warehouse)

    render_default_warehouse_conflict!
  end

  def default_warehouse_conflict?(warehouse)
    return false unless params.dig(:warehouse, :is_default) == "1"

    current_default = current_default_warehouse
    current_default.present? && current_default != warehouse
  end

  def render_default_warehouse_conflict!
    current_default = current_default_warehouse
    return false unless current_default

    @warehouse.errors.add(:is_default, default_warehouse_error_message(current_default))
    @positions_count = Warehouse.count
    render((action_name == "create" ? :new : :edit), status: :unprocessable_content)
    true
  end

  def current_default_warehouse
    Warehouse.find_by(is_default: true)
  end

  def default_warehouse_error_message(current_default)
    safe_join([
      "change the current default warehouse \"",
      view_context.link_to(current_default.name, warehouse_path(current_default), class: "link"),
      "\" before setting a new one"
    ])
  end
end
