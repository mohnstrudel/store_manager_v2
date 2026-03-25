# frozen_string_literal: true

class ProductsController < ApplicationController
  include MediaFormHandling

  before_action :set_product, only: %i[show edit update destroy] # DISABLED: publish_to_shopify, push_to_shopify
  before_action :load_form_collections, only: %i[new edit]

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
    @product.purchases.build do |purchase|
      purchase.payments.build
    end
  end

  # GET /products/1/edit
  def edit
  end

  # POST /products or /products.json
  def create
    payload = Product::FormPayload.new(params:)
    @product = Product.new(payload.product_attributes)

    respond_to do |format|
      @product.create_from_form!(
        editions_attributes: payload.editions_attributes,
        store_infos_attributes: payload.store_infos_attributes,
        purchase_attributes: payload.purchase_attributes,
        new_media_images: media_new_images_for(@product)
      )
      # DISABLED: Auto-push to Shopify on product create - not needed for now, will re-enable later
      # Shopify::CreateProductJob.perform_later(@product.id)

      format.html { redirect_to @product, notice: "Product was successfully created" }
      format.json { render :show, status: :created, location: @product }
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      @product = Product::FormRehydrator.new(product: @product, payload:).call
      load_form_collections
      format.html { render :new, status: :unprocessable_content }
      format.json { render json: @product.errors, status: :unprocessable_content }
    end
  end

  # PATCH/PUT /products/1 or /products/1.json
  def update
    payload = Product::FormPayload.new(params:)

    respond_to do |format|
      @product.apply_form_changes!(
        product_attributes: payload.product_attributes,
        editions_attributes: payload.editions_attributes,
        store_infos_attributes: payload.store_infos_attributes,
        media_attributes: normalized_media_attributes_for(@product),
        new_media_images: media_new_images_for(@product)
      )

      format.html { redirect_to product_url(@product), notice: "Product was successfully updated" }
      format.json { render :show, status: :ok, location: @product }
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      @product = Product::FormRehydrator.new(product: @product, payload:).call
      load_form_collections
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

  # DISABLED: Push to Shopify functionality - not needed for now, will re-enable later
  # def publish_to_shopify
  #   Shopify::CreateProductJob.perform_later(@product.id)
  #
  #   respond_to do |format|
  #     format.turbo_stream { flash.now[:notice] = "Product is being published to Shopify" }
  #     format.html { redirect_to products_path, notice: "Product is being published to Shopify" }
  #   end
  # end
  #
  # def push_to_shopify
  #   Shopify::UpdateProductJob.perform_later(@product.id)
  #
  #   respond_to do |format|
  #     format.turbo_stream { flash.now[:notice] = "Product updates are being pushed to Shopify" }
  #     format.html { redirect_to products_path, notice: "Product updates are being pushed to Shopify" }
  #   end
  # end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_product
    @product = Product.for_details.friendly.find(params[:id])
  end

  def load_form_collections
    @franchise_options = Franchise.order(:title)
    @brand_options = Brand.order(:title)
    @shape_options = Shape.order(:title)
    @size_options = Size.order(:value)
    @version_options = Version.order(:value)
    @color_options = Color.order(:value)
    @supplier_options = Supplier.order(title: :asc)
    @warehouse_options = Warehouse.order(name: :asc)
  end
end
