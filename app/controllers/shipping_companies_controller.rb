# frozen_string_literal: true

class ShippingCompaniesController < ApplicationController
  before_action :set_shipping_company, only: %i[show edit update destroy]

  def index
    @shipping_companies = ShippingCompany.order(:name)

    return unless stale?(etag: [@shipping_companies, request.inertia?], last_modified: @shipping_companies.maximum(:updated_at))

    render_inertia "ShippingCompanies/Index", serializer: ShippingCompanies::IndexResource,
      locals: {shipping_companies: @shipping_companies}
  end

  def show
    @purchase_items = @shipping_company.purchase_items.with_product_and_purchase

    render_inertia "ShippingCompanies/Show", serializer: ShippingCompanies::ShowResource,
      locals: {purchase_items: @purchase_items, shipping_company: @shipping_company}
  end

  def new
    @shipping_company = ShippingCompany.new

    render_inertia "ShippingCompanies/New", serializer: ShippingCompanies::NewResource,
      locals: {shipping_company: @shipping_company}
  end

  def edit
    render_inertia "ShippingCompanies/Edit", serializer: ShippingCompanies::EditResource,
      locals: {shipping_company: @shipping_company}
  end

  def create
    @shipping_company = ShippingCompany.new(shipping_company_params)

    if @shipping_company.save
      redirect_to shipping_company_url(@shipping_company), notice: "Shipping company was successfully created"
    else
      redirect_to new_shipping_company_url, inertia: inertia_errors(@shipping_company.errors)
    end
  end

  def update
    if @shipping_company.update(shipping_company_params)
      redirect_to shipping_company_url(@shipping_company), notice: "Shipping company was successfully updated"
    else
      redirect_to edit_shipping_company_url(@shipping_company), inertia: inertia_errors(@shipping_company.errors)
    end
  end

  def destroy
    @shipping_company.destroy

    redirect_to shipping_companies_url, notice: "Shipping company was successfully destroyed"
  end

  private

  def shipping_company_params
    params.fetch(:shipping_company, {}).permit(:name, :tracking_url)
  end

  def set_shipping_company
    @shipping_company = ShippingCompany.find(params.expect(:id))
  end
end
