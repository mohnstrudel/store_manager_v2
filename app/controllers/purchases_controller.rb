# frozen_string_literal: true

class PurchasesController < ApplicationController
  before_action :set_default_warehouse_id, only: %i[new edit]
  before_action :set_purchase_for_show, only: :show
  before_action :set_purchase, only: %i[edit update destroy]
  before_action :prepare_form_options, only: %i[new edit]

  # GET /purchases or /purchases.json
  def index
    @purchases = Purchase.for_listing.order(id: :desc).page(params[:page])
    @purchases = @purchases.search(params[:q]) if params[:q].present?
    @warehouses = Warehouse.order(name: :asc)

    return unless stale?(etag: [@purchases, @warehouses, request.inertia?], last_modified: @purchases.maximum(:updated_at))

    render inertia: "Purchases/Index", props: {
      purchases: @purchases.map { |purchase| helpers.purchase_index_props(purchase) },
      pagination: helpers.pagination_props(@purchases),
      search: {q: params[:q].to_s},
      warehouses: @warehouses.map { |warehouse| helpers.purchase_warehouse_props(warehouse) },
      move_path: move_path
    }
  end

  # GET /purchases/1 or /purchases/1.json
  def show
    render inertia: "Purchases/Show", props: helpers.purchase_show_props(
      @purchase,
      purchase_items: @purchase.purchase_items.for_purchase_details,
      payments: @purchase.payments.chronological,
      new_payment: @purchase.payments.new(payment_date: Time.zone.today)
    )
  end

  # GET /purchases/new
  def new
    @purchase = Purchase.new

    @purchase.product = Product.friendly.find(params.expect(:product)) if params[:product].present?
    @purchase.warehouse_id = @default_warehouse_id

    render inertia: "Purchases/New", props: helpers.purchase_form_props(
      @purchase,
      products: @product_options,
      suppliers: @suppliers,
      warehouses: @warehouse_options
    )
  end

  # GET /purchases/1/edit
  def edit
    @purchase.warehouse_id = @default_warehouse_id

    render inertia: "Purchases/Edit", props: helpers.purchase_form_props(
      @purchase,
      products: @product_options,
      suppliers: @suppliers,
      warehouses: @warehouse_options
    )
  end

  # POST /purchases or /purchases.json
  def create
    payload = Purchase::FormPayload.new(params:)
    @purchase = Purchase.new

    respond_to do |format|
      @purchase.create_from_form!(
        attributes: payload.attributes,
        initial_warehouse_id: payload.initial_warehouse_id,
        initial_payment_value: payload.initial_payment_value
      )
      format.html { redirect_to purchase_url(@purchase), notice: "Purchase was successfully created" }
      format.json { render :show, status: :created, location: @purchase }
    rescue ActiveRecord::RecordInvalid => e
      append_initial_payment_errors(@purchase, e.record)
      format.html { redirect_to new_purchase_url, inertia: inertia_errors(@purchase.errors) }
      format.json { render json: @purchase.errors, status: :unprocessable_content }
    end
  end

  # PATCH/PUT /purchases/1 or /purchases/1.json
  def update
    payload = Purchase::FormPayload.new(params:)

    respond_to do |format|
      @purchase.update_from_form!(attributes: payload.attributes.merge(slug: nil))
      format.html { redirect_to purchase_url(@purchase), notice: "Purchase was successfully updated" }
      format.json { render :show, status: :ok, location: @purchase }
    rescue ActiveRecord::RecordInvalid => e
      append_initial_payment_errors(@purchase, e.record)
      errors = @purchase.errors.dup
      @purchase.reload
      format.html { redirect_to edit_purchase_url(@purchase), inertia: inertia_errors(errors) }
      format.json { render json: errors, status: :unprocessable_content }
    end
  end

  # DELETE /purchases/1 or /purchases/1.json
  def destroy
    @purchase.destroy

    respond_to do |format|
      format.html { redirect_to purchases_url, notice: "Purchase was successfully destroyed" }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_purchase_for_show
    @purchase = Purchase.for_details.friendly.find(params.expect(:id))
  end

  def set_purchase
    @purchase = Purchase.friendly.find(params.expect(:id))
  end

  def set_default_warehouse_id
    @default_warehouse_id = Warehouse.find_by(is_default: true)&.id
  end

  def prepare_form_options
    @product_options = Product.with_store_references
    @suppliers = Supplier.order(title: :asc)
    @warehouse_options = Warehouse.order(name: :asc)
  end

  def append_initial_payment_errors(purchase, record)
    return unless record.is_a?(Payment)

    record.errors.full_messages.each do |message|
      purchase.errors.add(:base, "Initial payment #{message}")
    end
  end
end
