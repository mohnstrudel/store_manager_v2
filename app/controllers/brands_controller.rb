# frozen_string_literal: true

class BrandsController < ApplicationController
  before_action :set_brand, only: %i[show edit update destroy]

  def index
    @brands = Brand.order(:title)

    return unless stale?(etag: [@brands, request.inertia?], last_modified: @brands.maximum(:updated_at))

    render_inertia "Brands/Index", serializer: Brands::IndexResource, locals: {brands: @brands}
  end

  def show
    @brand = Brand.includes(:products).find(params.expect(:id))

    render_inertia "Brands/Show", serializer: Brands::ShowResource, locals: {brand: @brand}
  end

  def new
    @brand = Brand.new

    render_inertia "Brands/New", serializer: Brands::NewResource, locals: {brand: @brand}
  end

  def edit
    render_inertia "Brands/Edit", serializer: Brands::EditResource, locals: {brand: @brand}
  end

  def create
    @brand = Brand.new(brand_params)

    if @brand.save
      redirect_to brand_url(@brand), notice: "Brand was successfully created"
    else
      redirect_to new_brand_url, inertia: inertia_errors(@brand.errors)
    end
  end

  def update
    if @brand.update(brand_params)
      redirect_to brand_url(@brand), notice: "Brand was successfully updated"
    else
      redirect_to edit_brand_url(@brand), inertia: inertia_errors(@brand.errors)
    end
  end

  def destroy
    @brand.destroy

    redirect_to brands_url, notice: "Brand was successfully destroyed"
  end

  private

  def brand_params
    params.expect(brand: [:title])
  end

  def set_brand
    @brand = Brand.find(params.expect(:id))
  end
end
