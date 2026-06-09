# frozen_string_literal: true

class SalesController < ApplicationController
  before_action :set_sale_for_show, only: :show
  before_action :set_sale, only: %i[edit update destroy]

  # GET /sales
  def index
    @sales = Sale
      .for_listing
      .except_cancelled_or_completed
      .ordered_by_shop_created_at
      .search_by(params[:q])
      .page(params[:page])

    return unless stale?(etag: [@sales, request.inertia?], last_modified: @sales.maximum(:updated_at))

    render inertia: "Sales/Index", props: {
      sales: @sales.map { |sale| helpers.sale_listing_props(sale) },
      pagination: helpers.pagination_props(@sales),
      search: {q: params[:q].to_s},
      last_sync_at: helpers.format_last_fetched_at(Config.shopify_sales_sync_at),
      last_sync_time: Config.shopify_sales_sync_time
    }
  end

  # GET /sales/1
  def show
    render inertia: "Sales/Show", props: {
      sale: helpers.sale_showing_props(@sale)
    }
  end

  # GET /sales/new
  def new
    @sale = Sale.new
    render inertia: "Sales/New", props: helpers.sale_form_props(@sale)
  end

  # GET /sales/1/edit
  def edit
    render inertia: "Sales/Edit", props: helpers.sale_form_props(@sale)
  end

  # POST /sales
  def create
    payload = Sale::FormPayload.new(params:)
    @sale = Sale.new(payload.sale_attributes)

    @sale.create_from_form!(
      attributes: payload.sale_attributes,
      sale_item_attributes: payload.sale_item_attributes,
      shipping_address: payload.shipping_address_attributes,
      billing_address: payload.billing_address_attributes
    )
    redirect_to @sale, notice: "Sale was successfully created"
  rescue ActiveRecord::RecordInvalid => e
    append_sale_item_errors(e.record)
    redirect_to new_sale_url, inertia: inertia_errors(@sale.errors)
  end

  # PATCH/PUT /sales/1
  def update
    payload = Sale::FormPayload.new(params:)

    @sale.apply_form_changes!(
      attributes: payload.sale_attributes,
      sale_item_attributes: payload.sale_item_attributes,
      shipping_address: payload.shipping_address_attributes,
      billing_address: payload.billing_address_attributes
    )
    redirect_to @sale, notice: "Sale was successfully updated"
  rescue ActiveRecord::RecordInvalid => e
    append_sale_item_errors(e.record)
    redirect_to edit_sale_url(@sale), inertia: inertia_errors(@sale.errors)
  end

  # DELETE /sales/1
  def destroy
    @sale.destroy
    redirect_to sales_url, notice: "Sale was successfully destroyed", status: :see_other
  end

  private

  def set_sale_for_show
    @sale = Sale.for_details.friendly.find(params.expect(:id))
  end

  def set_sale
    @sale = Sale.for_edit.friendly.find(params.expect(:id))
  end

  def append_sale_item_errors(record)
    return unless record.is_a?(SaleItem)

    record.errors.full_messages.each do |message|
      @sale.errors.add(:base, "Sale item #{message}")
    end
  end
end
