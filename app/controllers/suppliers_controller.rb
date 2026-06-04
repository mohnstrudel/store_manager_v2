# frozen_string_literal: true

class SuppliersController < ApplicationController
  before_action :set_supplier, only: %i[show edit update destroy]

  # GET /suppliers or /suppliers.json
  def index
    @suppliers = Supplier.order(:title)

    render inertia: "Suppliers/Index", props: {
      suppliers: @suppliers.map { |supplier| helpers.supplier_props(supplier) }
    }
  end

  # GET /suppliers/1 or /suppliers/1.json
  def show
    @purchases = @supplier.purchases.for_supplier_details

    render inertia: "Suppliers/Show", props: {
      purchases: @purchases.map { |purchase| helpers.supplier_purchase_props(purchase) },
      supplier: helpers.supplier_props(@supplier)
    }
  end

  # GET /suppliers/new
  def new
    @supplier = Supplier.new

    render inertia: "Suppliers/New", props: helpers.supplier_form_props(@supplier)
  end

  # GET /suppliers/1/edit
  def edit
    render inertia: "Suppliers/Edit", props: helpers.supplier_form_props(@supplier)
  end

  # POST /suppliers or /suppliers.json
  def create
    @supplier = Supplier.new(supplier_params)

    respond_to do |format|
      if @supplier.save
        format.html { redirect_to supplier_url(@supplier), notice: "Supplier was successfully created" }
        format.json { render :show, status: :created, location: @supplier }
      else
        format.html { redirect_to new_supplier_url, inertia: inertia_errors(@supplier.errors) }
        format.json { render json: @supplier.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /suppliers/1 or /suppliers/1.json
  def update
    respond_to do |format|
      if @supplier.update(supplier_params.merge(slug: nil))
        format.html { redirect_to supplier_url(@supplier), notice: "Supplier was successfully updated" }
        format.json { render :show, status: :ok, location: @supplier }
      else
        format.html { redirect_to edit_supplier_url(@supplier.reload), inertia: inertia_errors(@supplier.errors) }
        format.json { render json: @supplier.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /suppliers/1 or /suppliers/1.json
  def destroy
    @supplier.destroy

    respond_to do |format|
      format.html { redirect_to suppliers_url, notice: "Supplier was successfully destroyed" }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_supplier
    @supplier = Supplier.friendly.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def supplier_params
    params.fetch(:supplier, {}).permit(:title)
  end
end
