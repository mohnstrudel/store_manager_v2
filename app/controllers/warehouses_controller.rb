# frozen_string_literal: true

class WarehousesController < ApplicationController
  include ActionView::Helpers::OutputSafetyHelper
  include MediaFormHandling

  before_action :set_warehouse, only: %i[edit update destroy]
  before_action :prepare_new_form, only: :new
  before_action :prepare_edit_form, only: :edit

  # GET /warehouses
  def index
    @warehouses = Warehouse.for_listing.order(:position)
    render inertia: "Warehouses/Index", props: {
      warehouses: @warehouses.map { |warehouse| warehouse_index_props(warehouse, @warehouses.size) }
    }
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

    @warehouse.create_from_form!(
      warehouse_params.to_h,
      new_media_images: media_new_images_for(@warehouse)
    )

    redirect_to @warehouse, notice: "Warehouse was successfully created"
  rescue ActiveRecord::RecordInvalid
    prepare_form_state(action: :new)
    render :new, status: :unprocessable_content
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
    prepare_form_state(action: :edit)
    render :edit, status: :unprocessable_content
  end

  # DELETE /warehouses/1
  def destroy
    warehouse_name = @warehouse.name

    @warehouse.destroy_if_empty!
    redirect_to warehouses_url, notice: "Warehouse #{warehouse_name} was successfully destroyed", status: :see_other
  rescue ActiveRecord::RecordInvalid
    flash[:error] = @warehouse.errors.full_messages.to_sentence
    redirect_to @warehouse
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
        to_warehouse_ids: []]
    )
  end

  def prepare_new_form
    @warehouse = Warehouse.new
    prepare_form_state(action: :new)
  end

  def prepare_edit_form
    prepare_form_state(action: :edit)
  end

  def prepare_form_state(action:)
    @positions_count = (action == :new) ? Warehouse.count + 1 : Warehouse.count
    warehouse = @warehouse || Warehouse.new
    @transition_destinations = Warehouse.where.not(id: warehouse.id).order(:name)
    @warehouse_transitions = WarehouseTransition.where(from_warehouse: warehouse).includes(:to_warehouse)
    replace_default_warehouse_conflict_error!
  end

  def default_warehouse_error_message(current_default)
    safe_join([
      "change the current default warehouse \"",
      view_context.link_to(current_default.name, warehouse_path(current_default), class: "link"),
      "\" before setting a new one"
    ])
  end

  def replace_default_warehouse_conflict_error!
    blocking_default = @warehouse.blocking_default_warehouse
    return unless blocking_default

    @warehouse.errors.delete(:is_default)
    @warehouse.errors.add(:is_default, default_warehouse_error_message(blocking_default))
  end

  def warehouse_index_props(warehouse, warehouses_count)
    {
      id: warehouse.id,
      path: warehouse_path(warehouse),
      edit_path: edit_warehouse_path(warehouse),
      position_path: warehouse_position_path(warehouse),
      position: warehouse.position,
      positions: (1..warehouses_count).to_a,
      name: warehouse.name.to_s,
      is_default: warehouse.is_default?,
      external_name_en: warehouse.external_name_en.presence || "N/A",
      cbm: warehouse.cbm.to_s,
      purchase_items_count: warehouse.purchase_items.size,
      has_purchase_items: warehouse.purchase_items.any?,
      payment_progress: {
        progress: warehouse.average_payment_progress.to_f,
        paid: "",
        price: "",
        debt: helpers.format_money(warehouse.total_debt).to_s
      }
    }
  end
end
