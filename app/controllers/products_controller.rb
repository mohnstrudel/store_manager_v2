class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update destroy variations]

  # GET /products or /products.json
  def index
    @products = Product
      .includes(:variations)
      .with_attached_images
      .order(:created_at)
      .page(params[:page])
    @products = @products.search(params[:q]) if params[:q].present?
  end

  # GET /products/1 or /products/1.json
  def show
    @active_sales = @product
      .product_sales.includes(
        :product,
        sale: :customer,
        variation: [:version, :color, :size]
      )
      .order(created_at: :asc)
      .select { |product_sale|
        Sale.active_status_names.include? product_sale.sale.status
      }
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

    respond_to do |format|
      if @product.save
        format.html { redirect_to product_url(@product), notice: "Product was successfully created." }
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
      if @product.update(product_params)
        @product.set_full_title

        format.html { redirect_to product_url(@product), notice: "Product was successfully updated." }
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
      format.html { redirect_to products_url, notice: "Product was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # GET /products/:id/variations?target=${html-id}
  def variations
    @target = params[:target]
    @variations = @product.variations.select do |i|
      OpenStruct.new(id: i.id, title: i.title) if i.title.present?
    end

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_product
    @product = Product.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def product_params
    params.fetch(:product, {}).permit(
      :title,
      :franchise_id,
      :shape_id,
      :target,
      brand_ids: [],
      color_ids: [],
      size_ids: [],
      supplier_ids: [],
      version_ids: [],
      images: []
    )
  end
end
