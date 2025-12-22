class ProductsController < ApplicationController
  include ActionView::Helpers::OutputSafetyHelper
  include HandlesMedia

  before_action :set_product, only: %i[show edit update destroy]

  # GET /products or /products.json
  def index
    @products = Product.listed.search_by(params[:q]).page(params[:page])
  end

  # GET /products/1 or /products/1.json
  def show
    @active_sales = @product.fetch_active_sale_items
    @complete_sales = @product.fetch_completed_sale_items
    @editions_sales_sums = @product.sum_editions_sale_items
    @editions_purchases_sums = @product.sum_editions_purchase_items
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
    @product = Product.new(product_params.except(:new_images))
    @product.build_editions

    respond_to do |format|
      if @product.save
        handle_new_images_for(@product)
        handle_new_purchase if purchase_params.present?
        Shopify::CreateProductJob.perform_later(@product.id)

        format.html { redirect_to @product, notice: "Product was successfully created" }
        format.json { render :show, status: :created, location: @product }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @product.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /products/1 or /products/1.json
  def update
    params_to_update = product_params.to_h
    if params_to_update[:sku].blank?
      params_to_update[:sku] = params_to_update[:title].parameterize
    end

    respond_to do |format|
      if @product.update(params_to_update.except(:new_images).merge(slug: nil))
        handle_new_images_for(@product)

        ActiveRecord::Base.transaction do
          @product.assign_attributes(full_title: Product.generate_full_title(@product))
          @product.build_editions
          @product.save
        end

        format.html { redirect_to product_url(@product), notice: "Product was successfully updated" }
        format.json { render :show, status: :ok, location: @product }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @product.errors, status: :unprocessable_content }
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
      "jobs statuses dashboard", root_url + "jobs/statuses", class: "link"
    )

    flash[:notice] = safe_join([
      "Success! Visit ",
      statuses_link,
      " to track synchronization progress"
    ])

    redirect_back_or_to(products_path)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_product
    @product = Product.includes(
      media: {image_attachment: :blob},
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
      .friendly
      .find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def product_params
    params.expect(product: [
      :title,
      :franchise_id,
      :shape_id,
      :target,
      :sku,
      :woo_id,
      :shopify_id,
      new_images: [],
      brand_ids: [],
      color_ids: [],
      size_ids: [],
      version_ids: [],
      media_attributes: [[
        :id,
        :alt,
        :position,
        :_destroy,
        :image
      ]],
      purchases_attributes: [[
        :item_price,
        :amount,
        :supplier_id,
        :order_reference,
        :warehouse_id,
        payments_attributes: [:value]
      ]]
    ])
  end

  def purchase_params
    params.dig(:product, :purchases_attributes, "0")
  end

  def handle_new_purchase
    warehouse_id = purchase_params[:warehouse_id]
    payment_value = purchase_params[:payments_attributes]&.values&.first&.[](:value)
    purchase = @product.purchases.last
    if purchase && warehouse_id
      @product.purchases.last.add_items_to_warehouse(warehouse_id)
      @product.purchases.last.link_with_sales
    end
    if purchase && payment_value
      purchase.payments.create(value: payment_value)
    end
  end
end
