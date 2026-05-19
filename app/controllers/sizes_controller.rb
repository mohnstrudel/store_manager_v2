# frozen_string_literal: true

class SizesController < ApplicationController
  before_action :set_size, only: %i[show edit update destroy]

  # GET /sizes or /sizes.json
  def index
    @sizes = Size.order(:value)

    render inertia: "Sizes/Index", props: {
      sizes: @sizes.map { |size| size_props(size) }
    }
  end

  # GET /sizes/1 or /sizes/1.json
  def show
    @size = Size.includes(:products).find(params[:id])

    render inertia: "Sizes/Show", props: {
      size: size_props(@size),
      products: @size.products.map { |product| product_props(product) }
    }
  end

  # GET /sizes/new
  def new
    @size = Size.new

    render inertia: "Sizes/New", props: form_props(@size)
  end

  # GET /sizes/1/edit
  def edit
    render inertia: "Sizes/Edit", props: form_props(@size)
  end

  # POST /sizes or /sizes.json
  def create
    @size = Size.new(size_params)

    respond_to do |format|
      if @size.save
        format.html { redirect_to size_url(@size), notice: "Size was successfully created" }
        format.json { render :show, status: :created, location: @size }
      else
        format.html do
          render inertia: "Sizes/New",
            props: form_props(@size),
            status: :unprocessable_content
        end
        format.json { render json: @size.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /sizes/1 or /sizes/1.json
  def update
    respond_to do |format|
      if @size.update(size_params)
        format.html { redirect_to size_url(@size), notice: "Size was successfully updated" }
        format.json { render :show, status: :ok, location: @size }
      else
        format.html do
          render inertia: "Sizes/Edit",
            props: form_props(@size),
            status: :unprocessable_content
        end
        format.json { render json: @size.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /sizes/1 or /sizes/1.json
  def destroy
    @size.destroy

    respond_to do |format|
      format.html { redirect_to sizes_url, notice: "Size was successfully destroyed" }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_size
    @size = Size.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def size_params
    params.fetch(:size, {}).permit(:value)
  end

  def form_props(size)
    {
      size: size_props(size),
      errors: size.errors.to_hash(true)
    }
  end

  def size_props(size)
    {
      id: size.id,
      value: size.value.to_s,
      created_at: size.created_at&.strftime("%-d. %b '%y %H:%M"),
      updated_at: size.updated_at&.strftime("%-d. %b '%y %H:%M")
    }
  end

  def product_props(product)
    {
      id: product.id,
      full_title: product.full_title.to_s,
      path: product_path(product)
    }
  end
end
