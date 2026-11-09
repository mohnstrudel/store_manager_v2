# frozen_string_literal: true

class WarehousesController < ApplicationController
  include MediaFormHandling

  before_action :set_warehouse, only: %i[edit update destroy]

  def index
    @warehouses = Warehouse.with_purchases_and_items.order(:position)

    return unless stale?(etag: [@warehouses], last_modified: @warehouses.maximum(:updated_at))

    render_inertia "Warehouses/Index", serializer: Warehouses::IndexResource, locals: {warehouses: @warehouses}
  end

  def new
    @warehouse = Warehouse.new
    render_inertia "Warehouses/New", serializer: Warehouses::FormResource,
      locals: {warehouse: @warehouse, positions_count: Warehouse.count + 1}
  end

  def edit
    render_inertia "Warehouses/Edit", serializer: Warehouses::FormResource,
      locals: {warehouse: @warehouse, positions_count: Warehouse.count}
  end

  def create
    attributes = warehouse_params.to_h
    @warehouse = Warehouse.new(attributes.except("to_warehouse_ids"))

    @warehouse.record(
      attributes,
      new_media_images: media_new_images_for(@warehouse)
    )

    redirect_to @warehouse, notice: "Warehouse was successfully created"
  rescue ActiveRecord::RecordInvalid
    redirect_to new_warehouse_path, inertia: inertia_errors(@warehouse.errors)
  end

  def update
    result = @warehouse.revise(
      attributes: warehouse_params.to_h,
      transition_ids: warehouse_params[:to_warehouse_ids],
      media_attributes: normalized_media_attributes_for(@warehouse),
      new_media_images: media_new_images_for(@warehouse)
    )

    if result == Warehouse::Revisable::TRANSITIONS_UPDATED
      redirect_to @warehouse, notice: "Warehouse transitions were successfully updated", status: :see_other
    else
      redirect_to @warehouse, notice: "Warehouse was successfully updated", status: :see_other
    end
  rescue ActiveRecord::RecordInvalid
    @warehouse.reload
    redirect_to edit_warehouse_path(@warehouse), inertia: inertia_errors(@warehouse.errors)
  end

  def destroy
    warehouse_name = @warehouse.name

    @warehouse.destroy_if_empty
    redirect_to warehouses_url, notice: "Warehouse #{warehouse_name} was successfully destroyed", status: :see_other
  rescue ActiveRecord::RecordInvalid
    flash[:alert] = @warehouse.errors.full_messages.to_sentence
    redirect_to @warehouse
  end

  private

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

  def set_warehouse
    @warehouse = Warehouse.find(params.expect(:id))
  end
end
