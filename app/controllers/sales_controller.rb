# frozen_string_literal: true

class SalesController < ApplicationController
  LISTING_FILTERS = %i[hide_partial_payments missing_purchases_only].freeze
  TAG_ID_FORMAT = /\A[1-9]\d*\z/
  UNAVAILABLE_TAG_NOTICE = "That tag is no longer available. Showing all tags."

  before_action :set_sale_for_show, only: :show
  before_action :set_sale_for_edit, only: :edit
  before_action :set_sale, only: %i[update destroy]

  def index
    catalog = SalesTag.order(:id).to_a
    return redirect_without_unavailable_tag if unavailable_tag_requested?(catalog)

    criteria = listing_criteria(catalog)
    @sales = Sale.listing(**criteria).page(params[:page])
    can_tag_sales = policy(:sale).update_tags?
    can_view_broken_sales = policy(:broken_sale).index?
    broken_problem_count = cached_broken_problem_count if can_view_broken_sales

    return unless stale?(etag: index_etag(criteria, catalog, can_tag_sales, broken_problem_count))

    render_inertia "Sales/Index", serializer: Sales::IndexResource,
      locals: {
        sales: @sales,
        criteria:,
        tag_catalog: catalog,
        can_tag_sales:,
        can_view_broken_sales:,
        broken_problem_count:
      }
  end

  def show
    render_inertia "Sales/Show", serializer: Sales::ShowResource,
      locals: {
        sale: @sale,
        can_view_profitability: policy(@sale).view_profitability?,
        tag_catalog: SalesTag.all,
        can_tag_sales: policy(:sale).update_tags?
      }
  end

  def new
    @sale = Sale.new
    render_inertia "Sales/New", serializer: Sales::FormResource, locals: {sale: @sale}
  end

  def edit
    render_inertia "Sales/Edit", serializer: Sales::FormResource, locals: {sale: @sale}
  end

  def create
    payload = Sale::FormPayload.new(params:)
    @sale = Sale.new(payload.sale_attributes)

    @sale.record(
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

    @sale.revise(
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

  def unavailable_tag_requested?(catalog)
    params[:tag_id].present? && available_tag_id(catalog).nil?
  end

  def available_tag_id(catalog)
    tag_id = requested_tag_id
    tag_id if catalog.any? { |tag| tag.id == tag_id }
  end

  def requested_tag_id
    value = params[:tag_id]
    value.to_i if value.is_a?(String) && value.match?(TAG_ID_FORMAT)
  end

  def redirect_without_unavailable_tag
    criteria = base_listing_criteria
    canonical = {
      q: criteria[:query].presence,
      sort: (criteria[:sort] unless criteria[:sort] == "newest"),
      **LISTING_FILTERS.index_with { |name| "1" if criteria[name] }
    }.compact

    redirect_to sales_path(canonical), notice: UNAVAILABLE_TAG_NOTICE
  end

  def base_listing_criteria
    {
      query: params[:q].to_s,
      sort: Sale.listing_sort(params[:sort]),
      **LISTING_FILTERS.index_with { |name| params[name] == "1" }
    }
  end

  def listing_criteria(catalog)
    {**base_listing_criteria, tag_id: available_tag_id(catalog)}
  end

  def cached_broken_problem_count
    Rails.cache.fetch("broken_sales/problem_count", expires_in: 1.minute) { BrokenSales::Counts.new.total }
  end

  def index_etag(criteria, catalog, can_tag_sales, broken_problem_count)
    [
      @sales, criteria, @sales.current_page, @sales.total_count,
      @sales.map { |sale| [sale.id, sale.sales_tags.map(&:id).sort, sale.shopify_variant_unlinked?] },
      catalog.map { |tag| [tag.id, tag.name, tag.color, tag.updated_at.to_fs(:usec)] },
      can_tag_sales, current_user.role, broken_problem_count
    ]
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
    @sale = Sale.preloaded.friendly.find(params.expect(:id))
  end

  def set_sale_for_edit
    @sale = Sale.with_item_variant_options_and_addresses.friendly.find(params.expect(:id))
  end

  def set_sale
    @sale = Sale.with_items_and_addresses.friendly.find(params.expect(:id))
  end
end
