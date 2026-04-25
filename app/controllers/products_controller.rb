# frozen_string_literal: true

class ProductsController < ApplicationController
  include MediaFormHandling

  before_action :set_product, only: %i[show edit update destroy]
  before_action :prepare_form_options, only: %i[new edit]

  # GET /products or /products.json
  def index
    @products = Product.listed.search_by(params[:q]).page(params[:page])
  end

  # GET /products/1 or /products/1.json
  def show
    @active_sales = @product.active_sale_items
    @complete_sales = @product.completed_sale_items
    @purchases = @product.purchases.includes(:supplier, :edition, purchase_items: :warehouse)
    @editions_sales_sums = @product.edition_sales_sums
    @editions_purchases_sums = @product.edition_purchase_sums
    @selected_id = params[:selected].presence&.to_i
  end

  # GET /products/new
  def new
    @product = Product.new
    @product.build_base_edition
    @purchase = default_purchase
  end

  # GET /products/1/edit
  def edit
    @product.build_base_edition
  end

  # POST /products or /products.json
  def create
    editing_payload = Product::Editing::Payload.new(params:)
    @product = Product.new

    respond_to do |format|
      @product.save_editing!(
        product_attributes: editing_payload.product_attributes,
        editions_attributes: editing_payload.editions_attributes,
        store_infos_attributes: editing_payload.store_infos_attributes,
        purchase_attributes: editing_payload.purchase_attributes,
        new_media_images: media_new_images_for(@product)
      )

      format.html { redirect_to @product, notice: "Product was successfully created" }
      format.json { render :show, status: :created, location: @product }
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      prepare_form_options
      @purchase = build_purchase_for_form(editing_payload.purchase_attributes)

      format.html { render :new, status: :unprocessable_content }
      format.json { render json: @product.errors, status: :unprocessable_content }
    end
  end

  # PATCH/PUT /products/1 or /products/1.json
  def update
    editing_payload = Product::Editing::Payload.new(params:)

    respond_to do |format|
      @product.save_editing!(
        product_attributes: editing_payload.product_attributes,
        editions_attributes: editing_payload.editions_attributes,
        store_infos_attributes: editing_payload.store_infos_attributes,
        media_attributes: normalized_media_attributes_for(@product),
        new_media_images: media_new_images_for(@product)
      )

      format.html { redirect_to product_url(@product), notice: "Product was successfully updated" }
      format.json { render :show, status: :ok, location: @product }
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      prepare_form_options

      format.html { render :edit, status: :unprocessable_content }
      format.json { render json: @product.errors, status: :unprocessable_content }
    end
  end

  # DELETE /products/1 or /products/1.json
  def destroy
    @product.destroy

    respond_to do |format|
      format.html { redirect_to products_url, notice: "Product was successfully destroyed" }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_product
    @product = Product.for_details.friendly.find(params[:id])
  end

  def prepare_form_options
    @franchise_options = Franchise.order(:title)
    @brand_options = Brand.order(:title)
    @shape_options = Product.shape_options
    @size_options = Size.order(:value)
    @version_options = Version.order(:value)
    @color_options = Color.order(:value)
    @supplier_options = Supplier.order(:title)
    @warehouse_options = Warehouse.order(:name)
  end

  def default_purchase
    Purchase.new(warehouse_id: Warehouse.find_by(is_default: true)&.id)
  end

  def build_purchase_for_form(purchase_attributes)
    return default_purchase if purchase_attributes.blank?

    purchase = Purchase.new(purchase_attributes.merge(product: @product))
    purchase.valid?
    purchase
  end
end
