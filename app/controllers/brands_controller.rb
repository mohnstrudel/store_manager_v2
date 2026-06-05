# frozen_string_literal: true

class BrandsController < ApplicationController
  before_action :set_brand, only: %i[show edit update destroy]

  # GET /brands or /brands.json
  def index
    @brands = Brand.order(:title)

    return unless stale?(etag: [@brands, request.inertia?], last_modified: @brands.maximum(:updated_at))

    render inertia: "Brands/Index", props: {
      brands: @brands.map { |brand| helpers.brand_props(brand) }
    }
  end

  # GET /brands/1 or /brands/1.json
  def show
    @brand = Brand.includes(:products).find(params.expect(:id))

    render inertia: "Brands/Show", props: {
      brand: helpers.brand_props(@brand),
      products: @brand.products.map { |product| helpers.product_props(product) }
    }
  end

  # GET /brands/new
  def new
    @brand = Brand.new

    render inertia: "Brands/New", props: helpers.brand_form_props(@brand)
  end

  # GET /brands/1/edit
  def edit
    render inertia: "Brands/Edit", props: helpers.brand_form_props(@brand)
  end

  # POST /brands or /brands.json
  def create
    @brand = Brand.new(brand_params)

    respond_to do |format|
      if @brand.save
        format.html { redirect_to brand_url(@brand), notice: "Brand was successfully created" }
        format.json { render :show, status: :created, location: @brand }
      else
        format.html { redirect_to new_brand_url, inertia: inertia_errors(@brand.errors) }
        format.json { render json: @brand.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /brands/1 or /brands/1.json
  def update
    respond_to do |format|
      if @brand.update(brand_params)
        format.html { redirect_to brand_url(@brand), notice: "Brand was successfully updated" }
        format.json { render :show, status: :ok, location: @brand }
      else
        format.html { redirect_to edit_brand_url(@brand), inertia: inertia_errors(@brand.errors) }
        format.json { render json: @brand.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /brands/1 or /brands/1.json
  def destroy
    @brand.destroy

    respond_to do |format|
      format.html { redirect_to brands_url, notice: "Brand was successfully destroyed" }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_brand
    @brand = Brand.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def brand_params
    params.fetch(:brand, {}).permit(:title)
  end
end
