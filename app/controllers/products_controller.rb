class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update destroy]

  # GET /products or /products.json
  def index
    @products = Product.listed.search_by(params[:q]).page(params[:page])
  end

  # GET /products/1 or /products/1.json
  def show
    @active_sales = @product.active_sale_items
    @complete_sales = @product.completed_sale_items
    @editions_sales_sums = @product.editions_sale_items_size
    @editions_purchases_sums = @product.editions_purchase_items_size
  end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/1/edit
  def edit
  end

  # POST /products or /products.json
  def create
    @product = Product.new(product_params)
    @product.build_editions

    respond_to do |format|
      if @product.save
        format.html { redirect_to product_url(@product), notice: "Product was successfully created" }
        format.json { render :show, status: :created, location: @product }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /products/1 or /products/1.json
  def update
    respond_to do |format|
      if @product.update(product_params.merge(slug: nil))
        @product.update_full_title
        @product.build_editions
        @product.save

        format.html { redirect_to product_url(@product), notice: "Product was successfully updated" }
        format.json { render :show, status: :ok, location: @product }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
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

  def pull
    limit = params[:limit]
    product_id = params[:id]

    if product_id.present?
      product = Product.friendly.find(product_id)
      Shopify::PullProductJob.perform_later(product.shopify_id)
    else
      Shopify::PullProductsJob.perform_later(limit:)
      Config.update_shopify_products_sync_time
    end

    statuses_link = view_context.link_to(
      "jobs statuses dashboard", root_url + "jobs/statuses"
    )

    flash[:notice] = "Success! Visit #{statuses_link} to track synchronization progress".html_safe

    redirect_back(fallback_location: products_path)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_product
    @product = Product.includes(
      purchases: [:product, :supplier, edition: [:version, :color, :size]],
      purchase_items: [:warehouse, :purchase],
      editions: [
        :version,
        :color,
        :size,
        {sale_items: :sale},
        {purchases: :supplier}
      ]
    )
      .with_attached_images
      .friendly
      .find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def product_params
    params.fetch(:product, {}).permit(
      :title,
      :franchise_id,
      :shape_id,
      :target,
      :sku,
      :woo_id,
      :shopify_id,
      brand_ids: [],
      color_ids: [],
      size_ids: [],
      supplier_ids: [],
      version_ids: [],
      images: []
    )
  end
end
