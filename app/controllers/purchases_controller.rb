# frozen_string_literal: true

class PurchasesController < ApplicationController
  before_action :set_default_warehouse_id, only: %i[new edit]
  before_action :set_purchase_for_show, only: :show
  before_action :set_purchase, only: %i[edit update destroy]
  before_action :prepare_form_options, only: %i[new edit]

  def index
    @purchases = Purchase.preloaded_for_listing.order(id: :desc).page(params[:page])
    @purchases = @purchases.search(params[:q]) if params[:q].present?
    @warehouses = Warehouse.order(name: :asc)

    return unless stale?(etag: [@purchases, @warehouses, request.inertia?], last_modified: @purchases.maximum(:updated_at))

    render_inertia "Purchases/Index", serializer: Purchases::IndexResource,
      locals: {purchases: @purchases, query: params[:q].to_s, warehouses: @warehouses}
  end

  def show
    render_inertia "Purchases/Show", serializer: Purchases::ShowResource,
      locals: {
        purchase: @purchase,
        purchase_items: @purchase.purchase_items.preloaded_for_purchase,
        payments: @purchase.payments.chronological,
        new_payment: @purchase.payments.new(payment_date: Time.zone.today)
      }
  end

  def new
    @purchase = Purchase.new

    @purchase.product = Product.friendly.find(params.expect(:product)) if params[:product].present?
    @purchase.warehouse_id = @default_warehouse_id

    render_inertia "Purchases/New", serializer: Purchases::FormResource, locals: form_locals
  end

  def edit
    @purchase.warehouse_id = @default_warehouse_id

    render_inertia "Purchases/Edit", serializer: Purchases::FormResource, locals: form_locals
  end

  def create
    payload = Purchase::FormPayload.new(params:)
    @purchase = Purchase.new

    respond_to do |format|
      @purchase.place(
        attributes: payload.attributes,
        warehouse_id: payload.initial_warehouse_id,
        payment_value: payload.initial_payment_value
      )
      format.html { redirect_to purchase_url(@purchase), notice: "Purchase was successfully created" }
      format.json { render :show, status: :created, location: @purchase }
    rescue ActiveRecord::RecordInvalid => e
      append_initial_payment_errors(@purchase, e.record)
      format.html { redirect_to new_purchase_url, inertia: inertia_errors(@purchase.errors) }
      format.json { render json: @purchase.errors, status: :unprocessable_content }
    end
  end

  def update
    payload = Purchase::FormPayload.new(params:)

    respond_to do |format|
      @purchase.update!(payload.attributes.merge(slug: nil))
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

  def destroy
    @purchase.destroy

    respond_to do |format|
      format.html { redirect_to purchases_url, notice: "Purchase was successfully destroyed" }
      format.json { head :no_content }
    end
  end

  private

  def form_locals
    {purchase: @purchase, products: @product_options, suppliers: @suppliers, warehouses: @warehouse_options}
  end

  def append_initial_payment_errors(purchase, record)
    return unless record.is_a?(Payment)

    record.errors.full_messages.each do |message|
      purchase.errors.add(:base, "Initial payment #{message}")
    end
  end

  def set_purchase_for_show
    @purchase = Purchase.preloaded.friendly.find(params.expect(:id))
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
end
