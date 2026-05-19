# frozen_string_literal: true

class CustomersController < ApplicationController
  before_action :set_customer, only: %i[show edit update destroy]

  # GET /customers
  def index
    @customers = Customer.order(:created_at)
    @customers = @customers.search(params[:q]) if params[:q].present?
    @customers = @customers.for_listing.page(params[:page])

    render inertia: "Customers/Index", props: {
      customers: @customers.map { |c| customer_props(c) },
      pagination: pagination_props(@customers),
      search: {q: params[:q].to_s}
    }
  end

  # GET /customers/1
  def show
    @active_sales = @customer.sales.active.for_details.ordered_by_shop_created_at
    @completed_sales = @customer.sales.completed.for_details.ordered_by_shop_created_at

    render inertia: "Customers/Show", props: {
      customer: customer_detail_props(@customer),
      active_sales: @active_sales.map { |s| sale_props(s) },
      completed_sales: @completed_sales.map { |s| sale_props(s) }
    }
  end

  # GET /customers/new
  def new
    @customer = Customer.new

    render inertia: "Customers/New", props: form_props(@customer)
  end

  # GET /customers/1/edit
  def edit
    render inertia: "Customers/Edit", props: form_props(@customer)
  end

  # POST /customers
  def create
    @customer = Customer.new(customer_params)

    if @customer.save
      redirect_to @customer, notice: "Customer was successfully created"
    else
      redirect_to new_customer_url, inertia: {errors: @customer.errors}
    end
  end

  # PATCH/PUT /customers/1
  def update
    if @customer.update(customer_params)
      redirect_to @customer, notice: "Customer was successfully updated", status: :see_other
    else
      redirect_to edit_customer_url(@customer), inertia: {errors: @customer.errors}
    end
  end

  # DELETE /customers/1
  def destroy
    @customer.destroy!
    redirect_to customers_url, notice: "Customer was successfully destroyed", status: :see_other
  end

  private

  def set_customer
    @customer = Customer.includes(:shopify_info, :woo_info).find(params[:id])
  end

  def customer_params
    params.fetch(:customer, {}).permit(:email, :first_name, :last_name, :phone)
  end

  def form_props(customer)
    {customer: customer_props(customer)}
  end

  def customer_props(customer)
    {
      id: customer.id,
      first_name: customer.first_name.to_s,
      last_name: customer.last_name.to_s,
      full_name: customer.full_name,
      email: customer.email.to_s,
      phone: customer.phone.to_s,
      woo_store_id: customer.woo_store_id.to_s,
      created_at: customer.created_at&.strftime("%-d. %b '%y %H:%M"),
      updated_at: customer.updated_at&.strftime("%-d. %b '%y %H:%M"),
      path: customer.persisted? ? customer_path(customer) : ""
    }
  end

  def customer_detail_props(customer)
    customer_props(customer).merge(
      shopify_id: customer.shopify_info&.store_id.to_s,
      shopify_id_short: customer.shopify_info&.id_short.to_s
    )
  end

  def sale_props(sale)
    store_type = if sale.shopify_info&.store_id.present?
      "shopify"
    elsif sale.woo_info&.store_id.present?
      "woo"
    end

    store_id = if sale.shopify_info&.store_id.present?
      sale.shopify_info.id_short
    elsif sale.woo_info&.store_id.present?
      sale.woo_info.store_id
    else
      sale.shopify_name.presence || sale.woo_store_id
    end

    {
      id: sale.id,
      path: sale_path(sale),
      store_id: store_id.to_s,
      store_type: store_type,
      status: sale.status,
      active: sale.active?,
      total: helpers.format_money(sale.total).to_s,
      country: sale.shipping_address&.country.to_s,
      city: sale.shipping_address&.city.to_s,
      note: sale.note.to_s,
      created_at: helpers.format_date(sale.shop_created_at.presence || sale.created_at).to_s,
      updated_at: helpers.format_date(sale.shop_updated_at.presence || sale.updated_at).to_s
    }
  end

  def pagination_props(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      limit: collection.limit_value
    }
  end
end
