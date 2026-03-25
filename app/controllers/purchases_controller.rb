# frozen_string_literal: true

class PurchasesController < ApplicationController
  before_action :set_default_warehouse_id, only: %i[new edit]
  before_action :set_purchase_for_show, only: :show
  before_action :set_purchase, only: %i[edit update destroy]
  before_action :load_form_collections, only: %i[new edit]

  # GET /purchases or /purchases.json
  def index
    @purchases = Purchase.for_listing.order(id: :desc).page(params[:page])
    @purchases = @purchases.search(params[:q]) if params[:q].present?
  end

  # GET /purchases/1 or /purchases/1.json
  def show
    @purchase_items = @purchase
      .purchase_items
      .for_purchase_details
      .order(updated_at: :desc)
    @payments = @purchase.payments.order(payment_date: :asc, created_at: :asc)
  end

  # GET /purchases/new
  def new
    @purchase = Purchase.new
    @purchase.payments.build
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
    attrs = purchase_params.to_h
    warehouse_id = attrs.delete("warehouse_id")
    @purchase = Purchase.new(attrs)

    respond_to do |format|
      if @purchase.save
        handle_warehouse_assignment_for(@purchase, warehouse_id)

        format.html { redirect_to purchase_url(@purchase), notice: "Purchase was successfully created" }
        format.json { render :show, status: :created, location: @purchase }
      else
        load_form_collections
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @purchase.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /purchases/1 or /purchases/1.json
  def update
    respond_to do |format|
      if @purchase.update(purchase_params.merge(slug: nil))
        format.html { redirect_to purchase_url(@purchase), notice: "Purchase was successfully updated" }
        format.json { render :show, status: :ok, location: @purchase }
      else
        load_form_collections
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

  # Only allow a list of trusted parameters through.
  def purchase_params
    params.expect(
      purchase: [:supplier_id,
        :product_id,
        :edition_id,
        :order_reference,
        :item_price,
        :amount,
        :purchase_id,
        :selected_items_ids,
        :warehouse_id,
        payments_attributes: [:id, :value, :purchase_id]]
    )
  end

  def load_form_collections
    @product_options = Product.with_store_references
    @suppliers = Supplier.order(title: :asc)
    @warehouse_options = Warehouse.order(name: :asc)
  end

  def handle_warehouse_assignment_for(purchase, warehouse_id)
    return if warehouse_id.blank?

    purchase.move_to_warehouse!(warehouse_id)
  end
end
