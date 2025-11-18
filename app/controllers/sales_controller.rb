class SalesController < ApplicationController
  include ActionView::Helpers::OutputSafetyHelper

  before_action :set_sale, only: %i[edit update destroy link_purchase_items]

  # GET /sales
  def index
    @sales = Sale
      .with_index_details
      .except_cancelled_or_completed
      .ordered_by_shop_created_at
      .search_by(params[:q])
      .page(params[:page])
  end

  # GET /sales/1
  def show
    @sale = Sale
      .with_show_details
      .friendly
      .find(params[:id])
  end

  # GET /sales/new
  def new
    @sale = Sale.new
  end

  # GET /sales/1/edit
  def edit
  end

  # POST /sales
  def create
    @sale = Sale.new(sale_params)

    if @sale.save
      linked_ids = @sale.link_with_purchase_items
      PurchasedNotifier.handle_product_purchase(purchase_item_ids: linked_ids)
      redirect_to @sale, notice: "Sale was successfully created"
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /sales/1
  def update
    if @sale.update(sale_params.merge(slug: nil))
      changes = @sale.saved_changes.transform_values(&:last)
      if changes[:status]
        Sale.update_order(woo_id: @sale.woo_id, status: changes[:status])
      end
      redirect_to @sale, notice: "Sale was successfully updated"
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /sales/1
  def destroy
    @sale.destroy
    redirect_to sales_url, notice: "Sale was successfully destroyed", status: :see_other
  end

  def link_purchase_items
    purchase_item_ids = @sale.link_with_purchase_items

    PurchasedNotifier.handle_product_purchase(purchase_item_ids:)

    redirect_to @sale, notice: "Success! Sold products were interlinked with purchased products"
  end

  def pull
    limit = params[:limit]

    sale_id = params[:id]

    if sale_id.present?
      sale = Sale.friendly.find(sale_id)
      Shopify::PullSaleJob.perform_later(sale.shopify_id) if sale.shopify_id.present?
      SyncWooOrdersJob.set(wait: 90.seconds).perform_later(id: sale.woo_id) if sale.woo_id.present?
    else
      Config.update_shopify_sales_sync_time
      Shopify::PullSalesJob.perform_later(limit:)
      SyncWooOrdersJob.set(wait: 90.seconds).perform_later(limit:)
    end

    statuses_link = view_context.link_to(
      "jobs statuses dashboard", root_url + "jobs/statuses", class: "link"
    )

    flash[:notice] = safe_join([
      "Success! Visit ",
      statuses_link,
      " to track synchronization progress"
    ])

    redirect_back(fallback_location: sales_path)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_sale
    @sale = Sale.friendly.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def sale_params
    params.fetch(:sale, {}).permit(
      :status,
      :address_1,
      :address_2,
      :city,
      :company,
      :country,
      :discount_total,
      :note,
      :postcode,
      :shipping_total,
      :state,
      :total,
      :woo_id,
      :customer_id,
      product_ids: [],
      sale_items_attributes: [
        :id,
        :product_id,
        :qty,
        :price,
        :woo_id,
        :_destroy
      ]
    )
  end
end
