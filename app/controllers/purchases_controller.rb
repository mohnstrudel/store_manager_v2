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

    @purchase.product = Product.friendly.find(params[:product]) if params[:product].present?
    @purchase.warehouse_id = @default_warehouse_id

    render inertia: "Purchases/New", props: form_props(@purchase)
  end

  # GET /purchases/1/edit
  def edit
    @purchase.warehouse_id = @default_warehouse_id

    render inertia: "Purchases/Edit", props: form_props(@purchase)
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
      format.html { redirect_to new_purchase_url, inertia: {errors: @purchase.errors} }
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
        format.html { redirect_to edit_purchase_url(@purchase), inertia: {errors: @purchase.errors} }
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

  def form_props(purchase)
    {
      purchase: purchase_form_props(purchase),
      options: form_options_props
    }
  end

  def form_options_props
    {
      products: select_option_props(@product_options) { |product| product.build_full_title_with_shop_id.to_s },
      suppliers: select_option_props(@suppliers) { |supplier| supplier.title.to_s },
      warehouses: select_option_props(@warehouse_options) { |warehouse| warehouse.name.to_s },
      product_variants_path: product_variants_path
    }
  end

  def purchase_form_props(purchase)
    {
      id: purchase.id,
      path: purchase.persisted? ? purchase_path(purchase) : "",
      product_id: purchase.product_id,
      variant_id: purchase.variant_id,
      supplier_id: purchase.supplier_id,
      order_reference: purchase.order_reference.to_s,
      item_price: purchase.item_price.to_s,
      amount: purchase.amount.to_s,
      warehouse_id: purchase.warehouse_id,
      payment_value: purchase.payment_value.to_s,
      variant_options: purchase_variant_options(purchase.product)
    }
  end

  def purchase_variant_options(product)
    return [] unless product

    select_option_props(product.fetch_variants_with_title) { |variant| variant.title.to_s }
  end

  def select_option_props(collection)
    collection.map do |record|
      {
        value: record.id,
        label: yield(record)
      }
    end
  end
end
