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

    render inertia: "Sales/Index", props: {
      sales: @sales.map { |sale| sale_index_props(sale) },
      pagination: pagination_props(@sales),
      search: {q: params[:q].to_s},
      last_sync_at: helpers.format_last_fetched_at(Config.shopify_sales_sync_at),
      last_sync_time: Config.shopify_sales_sync_time
    }
  end

  # GET /sales/1
  def show
    render inertia: "Sales/Show", props: {
      sale: sale_show_props(@sale)
    }
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
      sale_item_attributes: payload.sale_item_attributes,
      shipping_address: payload.shipping_address_attributes,
      billing_address: payload.billing_address_attributes
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
      sale_item_attributes: payload.sale_item_attributes,
      shipping_address: payload.shipping_address_attributes,
      billing_address: payload.billing_address_attributes
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

  def sale_index_props(sale)
    sale_base_props(sale).merge(
      customer_name: sale.customer.full_name.to_s,
      customer_email: sale.customer.email.to_s,
      sale_items: sale.sale_items.map { |sale_item| sale_index_sale_item_props(sale_item) }
    )
  end

  def sale_show_props(sale)
    sale_base_props(sale).merge(
      edit_path: edit_sale_path(sale),
      can_link_purchase_items: (sale.active? || sale.completed?) && sale.unlinked_sale_items?,
      link_purchase_items_path: sale_purchase_item_link_path(sale),
      pull_path: sale_pull_path(sale),
      shop_admin_url: helpers.sale_shop_link(sale),
      customer: customer_sale_props(sale.customer),
      shipping_address: sale_address_props(sale.shipping_address),
      billing_address: sale_address_props(sale.billing_address),
      billing_differs_from_shipping: sale.billing_differs_from_shipping?,
      note: sale.note.to_s,
      discount_total: helpers.format_money(sale.discount_total).to_s,
      shipping_total: helpers.format_money(sale.shipping_total).to_s,
      sale_items: sale.sale_items.map { |sale_item| sale_show_sale_item_props(sale_item) }
    )
  end

  def sale_base_props(sale)
    {
      id: sale.id,
      path: sale_path(sale),
      status: sale.status.to_s,
      active: sale.active?,
      completed: sale.completed?,
      total: helpers.format_money(sale.total).to_s,
      created_at: helpers.format_date(sale.shop_created_at.presence || sale.created_at).to_s,
      updated_at: helpers.format_date(sale.shop_updated_at.presence || sale.updated_at).to_s,
      shopify_name: sale.shopify_name.to_s,
      shopify_id: sale.shopify_id.to_s,
      shopify_id_short: sale.shopify_info&.id_short.to_s,
      woo_store_id: sale.woo_store_id.to_s,
      shop_identifier: sale.shop_identifier.to_s
    }
  end

  def sale_index_sale_item_props(sale_item)
    {
      id: sale_item.id,
      title: sale_item.title.to_s,
      qty: sale_item.qty.to_i,
      purchased_count: sale_item.purchase_items.size,
      product_thumb_url: helpers.thumb_url(sale_item.product),
      purchase_items: sale_item.purchase_items.map { |purchase_item| sale_index_purchase_item_props(purchase_item) }
    }
  end

  def sale_show_sale_item_props(sale_item)
    {
      id: sale_item.id,
      title: sale_item.title.to_s,
      price: helpers.format_money(sale_item.price).to_s,
      qty: sale_item.qty.to_i,
      product_path: product_path(sale_item.product),
      product_thumb_url: helpers.thumb_url(sale_item.product),
      purchase_items: sale_item.purchase_items.map { |purchase_item| sale_show_purchase_item_props(purchase_item) }
    }
  end

  def sale_index_purchase_item_props(purchase_item)
    {
      id: purchase_item.id,
      path: purchase_item_path(purchase_item),
      warehouse_name: purchase_item.warehouse.name.to_s,
      expenses: helpers.format_money(purchase_item.expenses).to_s
    }
  end

  def sale_show_purchase_item_props(purchase_item)
    {
      id: purchase_item.id,
      path: purchase_path(purchase_item.purchase),
      supplier_title: purchase_item.purchase.supplier.title.to_s,
      purchase_date: helpers.format_date(purchase_item.purchase.date).to_s,
      item_price: helpers.format_money(purchase_item.purchase.item_price).to_s,
      unlink_path: purchase_item_sale_item_link_path(purchase_item),
      current_warehouse_name: purchase_item.warehouse.name.to_s,
      current_warehouse_path: warehouse_path(
        purchase_item.warehouse,
        selected: purchase_item.id,
        anchor: purchase_item.id
      ),
      warehouse_movements: purchase_item.warehouse_movements.sort_by(&:moved_in).reverse.map do |movement|
        {
          moved_in: helpers.format_datetime(movement.moved_in).to_s,
          warehouse_name: movement.warehouse&.name.to_s
        }
      end
    }
  end

  def customer_sale_props(customer)
    {
      id: customer.id,
      first_name: customer.first_name.to_s,
      last_name: customer.last_name.to_s,
      full_name: customer.full_name.to_s,
      email: customer.email.to_s,
      shopify_id_short: customer.shopify_info&.id_short.to_s,
      shop_admin_url: helpers.customer_shop_link(customer)
    }
  end

  def sale_address_props(address)
    return nil unless address

    {
      address_1: address.address_1.to_s,
      address_2: address.address_2.to_s,
      city: address.city.to_s,
      company: address.company.to_s,
      country: address.country.to_s,
      email: address.email.to_s,
      first_name: address.first_name.to_s,
      last_name: address.last_name.to_s,
      phone: address.phone.to_s,
      postcode: address.postcode.to_s,
      state: address.state.to_s
    }
  end
end
