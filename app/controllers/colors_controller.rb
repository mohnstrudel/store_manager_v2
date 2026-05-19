# frozen_string_literal: true

class ColorsController < ApplicationController
  before_action :set_color, only: %i[show edit update destroy]

  # GET /colors or /colors.json
  def index
    @colors = Color.order(:value)

    render inertia: "Colors/Index", props: {
      colors: @colors.map { |color| color_props(color) }
    }
  end

  # GET /colors/1 or /colors/1.json
  def show
    @color = Color.includes(:products).find(params[:id])

    render inertia: "Colors/Show", props: {
      color: color_props(@color),
      products: @color.products.map { |product| product_props(product) }
    }
  end

  # GET /colors/new
  def new
    @color = Color.new

    render inertia: "Colors/New", props: form_props(@color)
  end

  # GET /colors/1/edit
  def edit
    render inertia: "Colors/Edit", props: form_props(@color)
  end

  # POST /colors or /colors.json
  def create
    @color = Color.new(color_params)

    respond_to do |format|
      if @color.save
        format.html { redirect_to color_url(@color), notice: "Color was successfully created" }
        format.json { render :show, status: :created, location: @color }
      else
        format.html { redirect_to new_color_url, inertia: {errors: @color.errors} }
        format.json { render json: @color.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /colors/1 or /colors/1.json
  def update
    respond_to do |format|
      if @color.update(color_params)
        format.html { redirect_to color_url(@color), notice: "Color was successfully updated" }
        format.json { render :show, status: :ok, location: @color }
      else
        format.html { redirect_to edit_color_url(@color), inertia: {errors: @color.errors} }
        format.json { render json: @color.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /colors/1 or /colors/1.json
  def destroy
    @color.destroy

    respond_to do |format|
      format.html { redirect_to colors_url, notice: "Color was successfully destroyed" }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_color
    @color = Color.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def color_params
    params.expect(color: [:value])
  end

  def form_props(color)
    {
      color: color_props(color)
    }
  end

  def color_props(color)
    {
      id: color.id,
      value: color.value.to_s,
      created_at: formatted_timestamp(color.created_at),
      updated_at: formatted_timestamp(color.updated_at)
    }
  end

  def product_props(product)
    {
      id: product.id,
      full_title: product.full_title.to_s,
      path: product_path(product)
    }
  end

  def formatted_timestamp(time)
    time&.strftime("%-d. %b '%y %H:%M")
  end
end
