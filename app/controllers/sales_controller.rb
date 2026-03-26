# frozen_string_literal: true

class SalesController < ApplicationController
  before_action :set_sale_for_show, only: :show
  before_action :set_sale, only: %i[edit update destroy]
  before_action :prepare_form_options, only: %i[new edit]

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
    @sale_items = []
  end

  # GET /sales/1/edit
  def edit
  end

  # POST /sales
  def create
    payload = Sale::FormPayload.new(params:)
    @sale = Sale.new(payload.sale_attributes)

    @sale.create_from_form!(
      attributes: payload.sale_attributes,
      sale_item_attributes: payload.sale_item_attributes
    )
    redirect_to @sale, notice: "Sale was successfully created"
  rescue ActiveRecord::RecordInvalid => e
    handle_failed_submit(:new, payload, e.record)
  end

  # PATCH/PUT /sales/1
  def update
    payload = Sale::FormPayload.new(params:)

    @sale.apply_form_changes!(
      attributes: payload.sale_attributes,
      sale_item_attributes: payload.sale_item_attributes
    )
    redirect_to @sale, notice: "Sale was successfully updated"
  rescue ActiveRecord::RecordInvalid => e
    handle_failed_submit(:edit, payload, e.record)
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

  def prepare_form_options
    @customer_options = Customer.order(:email)
    @product_shop_options = Product.with_store_references
  end

  def handle_failed_submit(template, payload, record)
    @sale.assign_attributes(payload.sale_attributes)
    append_sale_item_errors(record)
    @sale_items = payload.rebuild_submitted_sale_items(sale: @sale, invalid_record: record)
    prepare_form_options
    render template, status: :unprocessable_content
  end

  def append_sale_item_errors(record)
    return unless record.is_a?(SaleItem)

    record.errors.full_messages.each do |message|
      @sale.errors.add(:base, "Sale item #{message}")
    end
  end
end
