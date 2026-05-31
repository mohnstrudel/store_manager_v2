# frozen_string_literal: true

class ColorsController < ApplicationController
  before_action :set_color, only: %i[show edit update destroy]

  # GET /colors or /colors.json
  def index
    @colors = Color.order(:value)

    render inertia: "Colors/Index", props: {
      colors: @colors.map { |color| helpers.color_props(color) }
    }
  end

  # GET /colors/1 or /colors/1.json
  def show
    @color = Color.includes(:products).find(params[:id])

    render inertia: "Colors/Show", props: {
      color: helpers.color_props(@color),
      products: @color.products.map { |product| helpers.product_props(product) }
    }
  end

  # GET /colors/new
  def new
    @color = Color.new

    render inertia: "Colors/New", props: helpers.color_form_props(@color)
  end

  # GET /colors/1/edit
  def edit
    render inertia: "Colors/Edit", props: helpers.color_form_props(@color)
  end

  # POST /colors or /colors.json
  def create
    @color = Color.new(color_params)

    respond_to do |format|
      if @color.save
        format.html { redirect_to color_url(@color), notice: "Color was successfully created" }
        format.json { render :show, status: :created, location: @color }
      else
        format.html { redirect_to new_color_url, inertia: inertia_errors(@color.errors) }
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
        format.html { redirect_to edit_color_url(@color), inertia: inertia_errors(@color.errors) }
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

end
