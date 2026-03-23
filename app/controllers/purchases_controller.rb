# frozen_string_literal: true

class PurchasesController < ApplicationController
  include WarehouseMovementNotification

  before_action :set_default_warehouse_id, only: %i[new edit]
  before_action :set_purchase, only: %i[show edit update destroy]
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

  def move
    moved_count = Purchase.friendly
      .where(id: purchase_ids_for_movement)
      .sum { |purchase|
        Warehouse::Relocation.move(warehouse_id: params[:destination_id], purchase:)
      }

    flash_movement_notice(moved_count, Warehouse.find(params[:destination_id]))
    redirect_after_purchase_move
  end

  # Used for Turbo in:
  #  - purchase-edition_controller.js
  #  - app/views/purchases/editions.turbo_stream.slim
  #  - app/views/purchases/_form.html.slim
  # Shows edition select when we choose a product with editions
  def product_editions
    @target = params[:target]
    @product = Product.find(params[:product_id])
    @editions = @product.fetch_editions_with_title

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
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
  end

  def handle_warehouse_assignment_for(purchase, warehouse_id)
    return if warehouse_id.blank?

    purchase.add_items_to_warehouse(warehouse_id)
    purchase.link_with_sales
  end

  def purchase_ids_for_movement
    params[:selected_items_ids].presence || params[:purchase_id]
  end

  def redirect_after_purchase_move
    if params[:purchase_id].present?
      redirect_to purchase_path(Purchase.friendly.find(params[:purchase_id]))
    else
      redirect_to purchases_path
    end
  end
end
