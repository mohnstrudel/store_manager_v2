# frozen_string_literal: true

class CustomersController < ApplicationController
  before_action :set_customer, only: %i[show edit update destroy]

  # GET /customers
  def index
    @customers = Customer.order(:created_at)
    @customers = @customers.search(params[:q]) if params[:q].present?
    @customers = @customers.for_listing.page(params[:page])

    render inertia: "Customers/Index", props: {
      customers: @customers.map { |customer| helpers.customer_props(customer) },
      pagination: helpers.pagination_props(@customers),
      search: {q: params[:q].to_s}
    }
  end

  # GET /customers/1
  def show
    @active_sales = @customer.sales.active.for_details.ordered_by_shop_created_at
    @completed_sales = @customer.sales.completed.for_details.ordered_by_shop_created_at

    render inertia: "Customers/Show", props: {
      customer: helpers.customer_detail_props(@customer),
      active_sales: @active_sales.map { |sale| helpers.customer_sale_props(sale) },
      completed_sales: @completed_sales.map { |sale| helpers.customer_sale_props(sale) }
    }
  end

  # GET /customers/new
  def new
    @customer = Customer.new

    render inertia: "Customers/New", props: helpers.customer_form_props(@customer)
  end

  # GET /customers/1/edit
  def edit
    render inertia: "Customers/Edit", props: helpers.customer_form_props(@customer)
  end

  # POST /customers
  def create
    @customer = Customer.new(customer_params)

    if @customer.save
      redirect_to @customer, notice: "Customer was successfully created"
    else
      redirect_to new_customer_url, inertia: inertia_errors(@customer.errors)
    end
  end

  # PATCH/PUT /customers/1
  def update
    if @customer.update(customer_params)
      redirect_to @customer, notice: "Customer was successfully updated", status: :see_other
    else
      redirect_to edit_customer_url(@customer), inertia: inertia_errors(@customer.errors)
    end
  end

  # DELETE /customers/1
  def destroy
    @customer.destroy!
    redirect_to customers_url, notice: "Customer was successfully destroyed", status: :see_other
  end

  private

  def set_customer
    @customer = Customer.includes(:shopify_info, :woo_info).find(params.expect(:id))
  end

  def customer_params
    params.fetch(:customer, {}).permit(:email, :first_name, :last_name, :phone)
  end
end
