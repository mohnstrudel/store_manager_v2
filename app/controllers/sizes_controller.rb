# frozen_string_literal: true

class SizesController < ApplicationController
  before_action :set_size, only: %i[show edit update destroy]

  # GET /sizes or /sizes.json
  def index
    @sizes = Size.order(:value)

    return unless stale?(etag: [@sizes, request.inertia?], last_modified: @sizes.maximum(:updated_at))

    render inertia: "Sizes/Index", props: {
      sizes: @sizes.map { |size| helpers.size_props(size) }
    }
  end

  # GET /sizes/1 or /sizes/1.json
  def show
    @size = Size.includes(:products).find(params.expect(:id))

    render inertia: "Sizes/Show", props: {
      size: helpers.size_props(@size),
      products: @size.products.map { |product| helpers.product_props(product) }
    }
  end

  # GET /sizes/new
  def new
    @size = Size.new

    render inertia: "Sizes/New", props: helpers.size_form_props(@size)
  end

  # GET /sizes/1/edit
  def edit
    render inertia: "Sizes/Edit", props: helpers.size_form_props(@size)
  end

  # POST /sizes or /sizes.json
  def create
    @size = Size.new(size_params)

    respond_to do |format|
      if @size.save
        format.html { redirect_to size_url(@size), notice: "Size was successfully created" }
        format.json { render :show, status: :created, location: @size }
      else
        format.html { redirect_to new_size_url, inertia: inertia_errors(@size.errors) }
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
        format.html { redirect_to edit_size_url(@size), inertia: inertia_errors(@size.errors) }
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
    @size = Size.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def size_params
    params.fetch(:size, {}).permit(:value)
  end
end
