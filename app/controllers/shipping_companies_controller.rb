# frozen_string_literal: true

class ShippingCompaniesController < ApplicationController
  before_action :set_shipping_company, only: %i[show edit update destroy]

  # GET /shipping_companies or /shipping_companies.json
  def index
    @shipping_companies = ShippingCompany.order(:name)

    render inertia: "ShippingCompanies/Index", props: {
      shippingCompanies: @shipping_companies.map { |shipping_company| shipping_company_props(shipping_company) }
    }
  end

  # GET /shipping_companies/1 or /shipping_companies/1.json
  def show
    @purchase_items = @shipping_company.purchase_items.for_shipping_details

    render inertia: "ShippingCompanies/Show", props: {
      purchaseItems: @purchase_items.map { |purchase_item| purchase_item_props(purchase_item) },
      shippingCompany: shipping_company_props(@shipping_company)
    }
  end

  # GET /shipping_companies/new
  def new
    @shipping_company = ShippingCompany.new

    render inertia: "ShippingCompanies/New", props: form_props(@shipping_company)
  end

  # GET /shipping_companies/1/edit
  def edit
    render inertia: "ShippingCompanies/Edit", props: form_props(@shipping_company)
  end

  # POST /shipping_companies or /shipping_companies.json
  def create
    @shipping_company = ShippingCompany.new(shipping_company_params)

    respond_to do |format|
      if @shipping_company.save
        format.html { redirect_to shipping_company_url(@shipping_company), notice: "Shipping company was successfully created" }
        format.json { render :show, status: :created, location: @shipping_company }
      else
        format.html do
          render inertia: "ShippingCompanies/New",
            props: form_props(@shipping_company),
            status: :unprocessable_content
        end
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
        format.html do
          render inertia: "ShippingCompanies/Edit",
            props: form_props(@shipping_company),
            status: :unprocessable_content
        end
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
    @shipping_company = ShippingCompany.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def shipping_company_params
    params.fetch(:shipping_company, {}).permit(:name, :tracking_url)
  end

  def form_props(shipping_company)
    {
      errors: shipping_company.errors.to_hash(true),
      shippingCompany: shipping_company_props(shipping_company)
    }
  end

  def shipping_company_props(shipping_company)
    {
      created_at: formatted_timestamp(shipping_company.created_at),
      id: shipping_company.id,
      name: shipping_company.name.to_s,
      tracking_url: shipping_company.tracking_url.to_s.presence,
      updated_at: formatted_timestamp(shipping_company.updated_at)
    }
  end

  def purchase_item_props(purchase_item)
    {
      id: purchase_item.id,
      path: purchase_item_path(purchase_item),
      product_full_title: purchase_item.product.full_title.to_s,
      purchased_ago: helpers.time_ago_in_words(purchase_item.purchase&.date || purchase_item.created_at),
      tracking_number: purchase_item.tracking_number.to_s
    }
  end

  def formatted_timestamp(time)
    time&.strftime("%-d. %b '%y %H:%M")
  end
end
