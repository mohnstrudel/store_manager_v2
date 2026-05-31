# frozen_string_literal: true

class FranchisesController < ApplicationController
  before_action :set_franchise, only: %i[show edit update destroy]

  # GET /franchises or /franchises.json
  def index
    @franchises = Franchise.order(:title)

    render inertia: "Franchises/Index", props: {
      franchises: @franchises.map { |franchise| helpers.franchise_props(franchise) }
    }
  end

  # GET /franchises/1 or /franchises/1.json
  def show
    @franchise = Franchise.includes(:products).find(params[:id])

    render inertia: "Franchises/Show", props: {
      franchise: helpers.franchise_props(@franchise),
      products: @franchise.products.map { |product| helpers.product_props(product) }
    }
  end

  # GET /franchises/new
  def new
    @franchise = Franchise.new

    render inertia: "Franchises/New", props: helpers.franchise_form_props(@franchise)
  end

  # GET /franchises/1/edit
  def edit
    render inertia: "Franchises/Edit", props: helpers.franchise_form_props(@franchise)
  end

  # POST /franchises or /franchises.json
  def create
    @franchise = Franchise.new(franchise_params)

    respond_to do |format|
      if @franchise.save
        format.html { redirect_to franchise_url(@franchise), notice: "Franchise was successfully created" }
        format.json { render :show, status: :created, location: @franchise }
      else
        format.html { redirect_to new_franchise_url, inertia: inertia_errors(@franchise.errors) }
        format.json { render json: @franchise.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /franchises/1 or /franchises/1.json
  def update
    respond_to do |format|
      if @franchise.update(franchise_params)
        format.html { redirect_to franchise_url(@franchise), notice: "Franchise was successfully updated" }
        format.json { render :show, status: :ok, location: @franchise }
      else
        format.html { redirect_to edit_franchise_url(@franchise), inertia: inertia_errors(@franchise.errors) }
        format.json { render json: @franchise.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /franchises/1 or /franchises/1.json
  def destroy
    @franchise.destroy

    respond_to do |format|
      format.html { redirect_to franchises_url, notice: "Franchise was successfully destroyed" }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_franchise
    @franchise = Franchise.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def franchise_params
    params.fetch(:franchise, {}).permit(:title)
  end

end
