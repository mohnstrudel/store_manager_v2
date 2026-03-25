# frozen_string_literal: true

class SalesController < ApplicationController
  before_action :set_sale_for_show, only: :show
  before_action :set_sale, only: %i[edit update destroy]
  before_action :load_form_collections, only: %i[new edit]

  # GET /sales
  def index
    @sales = Sale
      .for_listing
      .except_cancelled_or_completed
      .ordered_by_shop_created_at
      .search_by(params[:q])
      .page(params[:page])
  end

  # GET /sales/1
  def show
    @sale_items = @sale.sale_items
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
    @sale = Sale.new

    @sale.create_from_form!(sale_params.to_h)
    redirect_to @sale, notice: "Sale was successfully created"
  rescue ActiveRecord::RecordInvalid
    load_form_collections
    render :new, status: :unprocessable_content
  end

  # PATCH/PUT /sales/1
  def update
    @sale.apply_form_changes!(sale_params.to_h)
    redirect_to @sale, notice: "Sale was successfully updated"
  rescue ActiveRecord::RecordInvalid
    load_form_collections
    render :edit, status: :unprocessable_content
  end

  # DELETE /sales/1
  def destroy
    @sale.destroy
    redirect_to sales_url, notice: "Sale was successfully destroyed", status: :see_other
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_sale_for_show
    @sale = Sale.for_details.friendly.find(params[:id])
  end

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

  def load_form_collections
    @customer_options = Customer.order(:email)
    @product_options = Product.order(:full_title)
    @product_shop_options = Product.with_store_references
  end

end
