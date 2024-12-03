class PurchasedProductsController < ApplicationController
  before_action :set_purchased_product, only: %i[show edit update destroy]

  # GET /warehouse_products
  def index
    @purchased_products = PurchasedProduct.all
  end

  # GET /purchased_products/1
  def show
  end

  # GET /purchased_products/new
  def new
    @warehouse = Warehouse.find(params[:warehouse_id])
    @purchased_product = PurchasedProduct.new(warehouse: @warehouse)
    @purchases = Purchase.includes(:product, :supplier).order(purchase_date: :desc, created_at: :desc)
    @shipping_companies = ShippingCompany.all
  end

  # GET /purchased_products/1/edit
  def edit
    set_data_for_edit
  end

  # POST /warehouse_products
  def create
    @purchased_product = PurchasedProduct.new(purchased_product_params)

    if @purchased_product.save
      redirect_to @purchased_product.warehouse, notice: "Purchased product was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /purchased_products/1
  def update
    if params[:deleted_img_ids].present?
      deleted_imgs = ActiveStorage::Attachment.where(id: params[:deleted_img_ids])
    end

    if @purchased_product.update(
      purchased_product_params.except(:redirect_to_product_sale)
    )
      path = purchased_product_params[:redirect_to_product_sale] ?
        @purchased_product.product_sale :
        @purchased_product

      deleted_imgs&.map(&:purge_later)

      redirect_to path, notice: "Purchased product was successfully updated.", status: :see_other
    else
      set_data_for_edit
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /purchased_products/1
  def destroy
    warehouse = @purchased_product.warehouse
    @purchased_product.destroy!

    redirect_to warehouse, notice: "Purchased product was successfully destroyed.", status: :see_other, turbolinks: false
  end

  def move
    ids = params[:selected_items_ids]
    destination_id = params[:destination_id]
    warehouse = Warehouse.find(params[:warehouse_id]) if params[:warehouse_id]
    purchase = Purchase.find(params[:purchase_id]) if params[:purchase_id]
    purchased_products = PurchasedProduct.where(id: ids)

    from_warehouses_and_products_ids = purchased_products
      .pluck(:warehouse_id, :id)
      .group_by(&:first)
      .transform_values do |pairs|
        pairs.map { |_warehouse_id, purchased_product_id| purchased_product_id }
      end

    moved_count = purchased_products.update_all(warehouse_id: destination_id)

    if moved_count > 0
      destination = Warehouse.find(destination_id)

      flash[:notice] = "Success! #{moved_count} purchased #{"product".pluralize(moved_count)} moved to: #{view_context.link_to(destination.name, warehouse_path(destination))}".html_safe

      from_warehouses_and_products_ids.each do |from_id, purchased_product_ids|
        Notification.dispatch(
          event: Notification.event_types[:warehouse_changed],
          context: {
            purchased_product_ids:,
            from_id:,
            to_id: destination_id
          }
        )
      end
    end

    if purchase
      redirect_to purchase_path(purchase)
    elsif params[:redirect_to_product_sale]
      product_sale = PurchasedProduct.find(ids.first).product_sale
      redirect_to product_sale
    else
      redirect_to warehouse_path(warehouse)
    end
  end

  def unlink
    purchased_product = PurchasedProduct.find(params[:id])
    product_sale = purchased_product.product_sale

    if purchased_product.update(product_sale: nil)
      redirect_to product_sale, notice: "Purchased product was successfully unlinked.", status: :see_other
    else
      redirect_to product_sale, alert: "Something went wrong. Try again later or contact the administrators.", status: :see_other, turbolinks: false
    end
  end

  private

  def set_purchased_product
    @purchased_product = PurchasedProduct.with_attached_images.find(params[:id])
  end

  def set_data_for_edit
    all_product_sales = ProductSale.includes(
      :product,
      sale: [:customer],
      variation: [:color, :size, :version]
    )
    @product_sales = all_product_sales.where(
      product_id: @purchased_product.product
    ) + all_product_sales.where.not(
      product_id: @purchased_product.product
    )
    @purchases = Purchase.includes(:product, :supplier).order(
      purchase_date: :desc,
      created_at: :desc
    )
    @shipping_companies = ShippingCompany.all
  end

  # Only allow a list of trusted parameters through.
  def purchased_product_params
    params.require(:purchased_product).permit(
      :length,
      :width,
      :height,
      :weight,
      :expenses,
      :shipping_price,
      :tracking_number,
      :warehouse_id,
      :purchase_id,
      :product_sale_id,
      :redirect_to_product_sale,
      :shipping_company_id,
      deleted_img_ids: [],
      images: []
    )
  end
end
