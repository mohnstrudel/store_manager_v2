# frozen_string_literal: true

class ShippingCompaniesController < ApplicationController
  before_action :set_shipping_company, only: %i[show edit update destroy]

  # GET /shipping_companies or /shipping_companies.json
  def index
    @shipping_companies = ShippingCompany.order(:name)

    render inertia: "ShippingCompanies/Index", props: {
      shippingCompanies: @shipping_companies.map { |shipping_company| helpers.shipping_company_props(shipping_company) }
    }
  end

  # GET /shipping_companies/1 or /shipping_companies/1.json
  def show
    @purchase_items = @shipping_company.purchase_items.for_shipping_details

    render inertia: "ShippingCompanies/Show", props: {
      purchaseItems: @purchase_items.map { |purchase_item| helpers.shipping_company_purchase_item_props(purchase_item) },
      shippingCompany: helpers.shipping_company_props(@shipping_company)
    }
  end

  # GET /shipping_companies/new
  def new
    @shipping_company = ShippingCompany.new

    render inertia: "ShippingCompanies/New", props: helpers.shipping_company_form_props(@shipping_company)
  end

  # GET /shipping_companies/1/edit
  def edit
    render inertia: "ShippingCompanies/Edit", props: helpers.shipping_company_form_props(@shipping_company)
  end

  # POST /shipping_companies or /shipping_companies.json
  def create
    @shipping_company = ShippingCompany.new(shipping_company_params)

    respond_to do |format|
      if @shipping_company.save
        format.html { redirect_to shipping_company_url(@shipping_company), notice: "Shipping company was successfully created" }
        format.json { render :show, status: :created, location: @shipping_company }
      else
        format.html { redirect_to new_shipping_company_url, inertia: inertia_errors(@shipping_company.errors) }
        format.json { render json: @shipping_company.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /shipping_companies/1 or /shipping_companies/1.json
  def update
    respond_to do |format|
      if @shipping_company.update(shipping_company_params)
        format.html { redirect_to shipping_company_url(@shipping_company), notice: "Shipping company was successfully updated" }
        format.json { render :show, status: :ok, location: @shipping_company }
      else
        format.html { redirect_to edit_shipping_company_url(@shipping_company), inertia: inertia_errors(@shipping_company.errors) }
        format.json { render json: @shipping_company.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /shipping_companies/1 or /shipping_companies/1.json
  def destroy
    @shipping_company.destroy

    respond_to do |format|
      format.html { redirect_to shipping_companies_url, notice: "Shipping company was successfully destroyed" }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_shipping_company
    @shipping_company = ShippingCompany.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def shipping_company_params
    params.fetch(:shipping_company, {}).permit(:name, :tracking_url)
  end
end
