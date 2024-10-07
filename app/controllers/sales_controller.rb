class SalesController < ApplicationController
  before_action :set_sale, only: %i[show edit update destroy link_purchased_products]

  # GET /sales
  def index
    sale_records = Sale
      .includes(
        :customer,
        product_sales: [
          product: [images_attachments: :blob],
          variation: [
            :version,
            :color,
            :size
          ]
        ]
      )
      .order(
        Arel.sql("woo_created_at DESC, created_at DESC, CAST(woo_id AS int) DESC")
      )
      .page(params[:page])

    @sales = if params[:q].present?
      sale_records
        .search(params[:q])
    else
      sale_records
        .where.not(status: "cancelled")
    end
  end

  # GET /sales/1
  def show
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
      redirect_to @sale, notice: "Sale was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /sales/1
  def update
    if @sale.update(sale_params.merge(slug: nil))
      changes = @sale.saved_changes.transform_values(&:last)
      if changes[:status]
        Sale.update_order(woo_id: @sale.woo_id, status: changes[:status])
      end
      redirect_to @sale, notice: "Sale was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /sales/1
  def destroy
    @sale.destroy
    redirect_to sales_url, notice: "Sale was successfully destroyed.", status: :see_other
  end

  def link_purchased_products
    @sale.product_sales.each(&:link_purchased_products)
    redirect_to @sale, notice: "Success! Sold products were interlinked with purchased products."
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
      product_sales_attributes: [
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
