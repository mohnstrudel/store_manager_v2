# frozen_string_literal: true

class PurchasesController < ApplicationController
  include PurchaseShowState

  before_action :set_default_warehouse_id, only: %i[new edit]
  before_action :set_purchase_for_show, only: :show
  before_action :set_purchase, only: %i[edit update destroy]
  before_action :prepare_form_options, only: %i[new edit]

  # GET /purchases or /purchases.json
  def index
    @purchases = Purchase.for_listing.order(id: :desc).page(params[:page])
    @purchases = @purchases.search(params[:q]) if params[:q].present?

    render inertia: "Purchases/Index", props: {
      purchases: @purchases.map { |purchase| purchase_index_props(purchase) },
      pagination: pagination_props(@purchases),
      search: {q: params[:q].to_s},
      warehouses: Warehouse.order(name: :asc).map { |warehouse| warehouse_props(warehouse) },
      move_path: move_path
    }
  end

  # GET /purchases/1 or /purchases/1.json
  def show
    render inertia: "Purchases/Show", props: purchase_show_props
  end

  # GET /purchases/new
  def new
    @purchase = Purchase.new
    @initial_payment_value = nil
    if params[:product]
      product = Product.friendly.find(params[:product])
      @purchase.product = product
    end
  end

  # GET /purchases/1/edit
  def edit
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
      prepare_form_options
      @initial_payment_value = payload.initial_payment_value
      format.html { render :new, status: :unprocessable_content }
      format.json { render json: @purchase.errors, status: :unprocessable_content }
    end
  end

  # PATCH/PUT /purchases/1 or /purchases/1.json
  def update
    payload = Purchase::FormPayload.new(params:)

    respond_to do |format|
      if @purchase.update(payload.attributes.merge(slug: nil))
        format.html { redirect_to purchase_url(@purchase), notice: "Purchase was successfully updated" }
        format.json { render :show, status: :ok, location: @purchase }
      else
        prepare_form_options
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @purchase.errors, status: :unprocessable_content }
      end
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
    @purchase = Purchase.for_details.friendly.find(params[:id])
  end

  def set_purchase
    @purchase = Purchase.friendly.find(params[:id])
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

  def purchase_index_props(purchase)
    {
      id: purchase.id,
      path: purchase_path(purchase),
      edit_path: edit_purchase_path(purchase),
      product_title: purchase.product.full_title.to_s,
      product_thumb_url: helpers.thumb_url(purchase.product),
      variant_title: purchase.variant&.title.to_s,
      order_reference: purchase.order_reference.to_s,
      supplier_title: purchase.supplier.title.to_s,
      amount: purchase.amount.to_i,
      purchase_items_count: purchase.purchase_items.size,
      warehouse_counts: purchase.purchase_items.group_by(&:warehouse).map do |warehouse, purchase_items|
        {
          warehouse_name: warehouse.name.to_s,
          count: purchase_items.count
        }
      end,
      payment_progress: payment_progress_props(purchase)
    }
  end
end
