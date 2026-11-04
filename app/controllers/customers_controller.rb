# frozen_string_literal: true

class CustomersController < ApplicationController
  before_action :set_customer, only: %i[show edit update destroy]

  def index
    @customers = Customer.order(:created_at)
    @customers = @customers.search(params[:q]) if params[:q].present?
    @customers = @customers.with_woo_info.page(params[:page])

    return unless stale?(etag: [@customers, request.inertia?], last_modified: @customers.maximum(:updated_at))

    render_inertia "Customers/Index", serializer: Customers::IndexResource,
      locals: {customers: @customers, query: params[:q].to_s}
  end

  def show
    @active_sales = @customer.sales.active.preloaded.ordered_by_shop_created_at
    @completed_sales = @customer.sales.completed.preloaded.ordered_by_shop_created_at

    render_inertia "Customers/Show", serializer: Customers::ShowResource,
      locals: {customer: @customer, active_sales: @active_sales, completed_sales: @completed_sales}
  end

  def new
    @customer = Customer.new

    render_inertia "Customers/New", serializer: Customers::NewResource, locals: {customer: @customer}
  end

  def edit
    render_inertia "Customers/Edit", serializer: Customers::EditResource, locals: {customer: @customer}
  end

  def create
    @customer = Customer.new(customer_params)

    if @customer.save
      redirect_to @customer, notice: "Customer was successfully created"
    else
      redirect_to new_customer_url, inertia: inertia_errors(@customer.errors)
    end
  end

  def update
    if @customer.update(customer_params)
      redirect_to @customer, notice: "Customer was successfully updated", status: :see_other
    else
      redirect_to edit_customer_url(@customer), inertia: inertia_errors(@customer.errors)
    end
  end

  def destroy
    @customer.destroy!
    redirect_to customers_url, notice: "Customer was successfully destroyed", status: :see_other
  end

  private

  def customer_params
    params.fetch(:customer, {}).permit(:email, :first_name, :last_name, :phone)
  end

  def set_customer
    @customer = Customer.includes(:shopify_info, :woo_info).find(params.expect(:id))
  end
end
