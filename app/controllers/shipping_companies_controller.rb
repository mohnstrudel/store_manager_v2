class ShippingCompaniesController < ApplicationController
  before_action :set_shipping_company, only: %i[show edit update destroy]

  # GET /shipping_companies or /shipping_companies.json
  def index
    @shipping_companies = ShippingCompany.order(:name)
  end

  # GET /shipping_companies/1 or /shipping_companies/1.json
  def show
    @purchase_items = @shipping_company.purchase_items.includes(:product, :purchase, edition: [:color, :size, :version])
  end

  # GET /shipping_companies/new
  def new
    @shipping_company = ShippingCompany.new
  end

  # GET /shipping_companies/1/edit
  def edit
  end

  # POST /shipping_companies or /shipping_companies.json
  def create
    @shipping_company = ShippingCompany.new(shipping_company_params)

    respond_to do |format|
      if @shipping_company.save
        format.html { redirect_to shipping_company_url(@shipping_company), notice: "Shipping company was successfully created" }
        format.json { render :show, status: :created, location: @shipping_company }
      else
        format.html { render :new, status: :unprocessable_content }
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
        format.html { render :edit, status: :unprocessable_content }
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
end
