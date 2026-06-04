# frozen_string_literal: true

class WarehousesController < ApplicationController
  include MediaFormHandling

  before_action :set_warehouse, only: %i[edit update destroy]

  # GET /warehouses
  def index
    @warehouses = Warehouse.for_listing.order(:position)
    render inertia: "Warehouses/Index", props: {
      warehouses: @warehouses.map { |warehouse| helpers.warehouse_listing_props(warehouse, @warehouses.size) }
    }
  end

  # GET /warehouses/new
  def new
    @warehouse = Warehouse.new
    render inertia: "Warehouses/New", props: helpers.warehouse_new_props(@warehouse)
  end

  # GET /warehouses/1/edit
  def edit
    render inertia: "Warehouses/Edit", props: helpers.warehouse_edit_props(@warehouse)
  end

  # POST /warehouses
  def create
    attributes = warehouse_params.to_h
    @warehouse = Warehouse.new(attributes.except("to_warehouse_ids"))

    @warehouse.create_from_form!(
      attributes,
      new_media_images: media_new_images_for(@warehouse)
    )

    redirect_to @warehouse, notice: "Warehouse was successfully created"
  rescue ActiveRecord::RecordInvalid
    redirect_to new_warehouse_path, inertia: inertia_errors(@warehouse.errors)
  end

  # PATCH/PUT /warehouses/1
  def update
    result = @warehouse.apply_form_changes!(
      attributes: warehouse_params.to_h,
      transition_ids: params.dig(:warehouse, :to_warehouse_ids),
      media_attributes: normalized_media_attributes_for(@warehouse),
      new_media_images: media_new_images_for(@warehouse)
    )

    if result == Warehouse::Editing::TRANSITIONS_UPDATED
      redirect_to @warehouse, notice: "Warehouse transitions were successfully updated", status: :see_other
    else
      redirect_to @warehouse, notice: "Warehouse was successfully updated", status: :see_other
    end
  rescue ActiveRecord::RecordInvalid
    @warehouse.reload
    redirect_to edit_warehouse_path(@warehouse), inertia: inertia_errors(@warehouse.errors)
  end

  # DELETE /warehouses/1
  def destroy
    warehouse_name = @warehouse.name

    @warehouse.destroy_if_empty!
    redirect_to warehouses_url, notice: "Warehouse #{warehouse_name} was successfully destroyed", status: :see_other
  rescue ActiveRecord::RecordInvalid
    flash[:alert] = @warehouse.errors.full_messages.to_sentence
    redirect_to @warehouse
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_warehouse
    @warehouse = Warehouse.find(params.expect(:id))
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
        to_warehouse_ids: []]
    )
  end
end
