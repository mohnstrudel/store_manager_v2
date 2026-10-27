# frozen_string_literal: true

class SalesController < ApplicationController
  LISTING_FILTERS = %i[hide_partial_payments missing_purchases_only].freeze

  before_action :set_sale_for_show, only: :show
  before_action :set_sale, only: %i[edit update destroy]

  def index
    criteria = listing_criteria
    @sales = Sale.listing(**criteria).page(params[:page])
    pagination = helpers.pagination_props(@sales)

    return unless stale?(etag: [@sales, request.inertia?, criteria, pagination], last_modified: @sales.maximum(:updated_at))

    render inertia: "Sales/Index", props: {
      sales: @sales.map { |sale| helpers.sale_listing_props(sale) },
      pagination:,
      search: {q: criteria[:query]},
      sort: criteria[:sort],
      filters: criteria.slice(*LISTING_FILTERS),
      last_sync_at: helpers.format_last_fetched_at(Config.shopify_sales_sync_at),
      last_sync_time: Config.shopify_sales_sync_time
    }
  end

  def show
    render inertia: "Sales/Show", props: {
      sale: helpers.sale_showing_props(@sale, can_view_profitability: policy(@sale).view_profitability?)
    }
  end

  def new
    @sale = Sale.new
    render inertia: "Sales/New", props: helpers.sale_form_props(@sale)
  end

  def edit
    render inertia: "Sales/Edit", props: helpers.sale_form_props(@sale)
  end

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
    append_sale_item_errors(e.record, payload:)
    redirect_to new_sale_url, inertia: inertia_errors(@sale.errors)
  end

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
    append_sale_item_errors(e.record, payload:)
    redirect_to edit_sale_url(@sale), inertia: inertia_errors(@sale.errors)
  end

  def destroy
    @sale.destroy
    redirect_to sales_url, notice: "Sale was successfully destroyed", status: :see_other
  end

  private

  def listing_criteria
    {
      query: params[:q].to_s,
      sort: Sale.listing_sort(params[:sort]),
      **LISTING_FILTERS.index_with { |name| params[name] == "1" }
    }
  end

  def append_sale_item_errors(record, payload:)
    return unless record.is_a?(SaleItem)

    submitted_items = payload.rebuild_submitted_sale_items(sale: @sale, invalid_record: record)
    row_index = submitted_items.index(record)
    return if row_index.nil?

    record.errors.each do |error|
      attribute = (error.attribute == :base) ? "base" : error.attribute
      @sale.errors.add("sale_items.#{row_index}.#{attribute}", error.message)
    end
  end

  def set_sale_for_show
    @sale = Sale.for_details.friendly.find(params.expect(:id))
  end

  def set_sale
    @sale = Sale.for_edit.friendly.find(params.expect(:id))
  end
end
