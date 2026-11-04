# frozen_string_literal: true

class SuppliersController < ApplicationController
  before_action :set_supplier, only: %i[show edit update destroy]

  def index
    @suppliers = Supplier.order(:title)

    return unless stale?(etag: [@suppliers, request.inertia?], last_modified: @suppliers.maximum(:updated_at))

    render_inertia "Suppliers/Index", serializer: Suppliers::IndexResource, locals: {suppliers: @suppliers}
  end

  def show
    @purchases = @supplier.purchases.with_product_payments_and_variant

    render_inertia "Suppliers/Show", serializer: Suppliers::ShowResource, locals: {purchases: @purchases, supplier: @supplier}
  end

  def new
    @supplier = Supplier.new

    render_inertia "Suppliers/New", serializer: Suppliers::NewResource, locals: {supplier: @supplier}
  end

  def edit
    render_inertia "Suppliers/Edit", serializer: Suppliers::EditResource, locals: {supplier: @supplier}
  end

  def create
    @supplier = Supplier.new(supplier_params)

    if @supplier.save
      redirect_to supplier_url(@supplier), notice: "Supplier was successfully created"
    else
      redirect_to new_supplier_url, inertia: inertia_errors(@supplier.errors)
    end
  end

  def update
    if @supplier.update(supplier_params.merge(slug: nil))
      redirect_to supplier_url(@supplier), notice: "Supplier was successfully updated"
    else
      redirect_to edit_supplier_url(@supplier.reload), inertia: inertia_errors(@supplier.errors)
    end
  end

  def destroy
    @supplier.destroy

    redirect_to suppliers_url, notice: "Supplier was successfully destroyed"
  end

  private

  def supplier_params
    params.expect(supplier: [:title])
  end

  def set_supplier
    @supplier = Supplier.friendly.find(params.expect(:id))
  end
end
