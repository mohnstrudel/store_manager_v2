# frozen_string_literal: true

class SizesController < ApplicationController
  before_action :set_size, only: %i[show edit update destroy]

  def index
    @sizes = Size.order(:value)

    return unless stale?(etag: [@sizes, request.inertia?], last_modified: @sizes.maximum(:updated_at))

    render_inertia "Sizes/Index", serializer: Sizes::IndexResource, locals: {sizes: @sizes}
  end

  def show
    @size = Size.includes(:products).find(params.expect(:id))

    render_inertia "Sizes/Show", serializer: Sizes::ShowResource, locals: {size: @size}
  end

  def new
    @size = Size.new

    render_inertia "Sizes/New", serializer: Sizes::NewResource, locals: {size: @size}
  end

  def edit
    render_inertia "Sizes/Edit", serializer: Sizes::EditResource, locals: {size: @size}
  end

  def create
    @size = Size.new(size_params)

    if @size.save
      redirect_to size_url(@size), notice: "Size was successfully created"
    else
      redirect_to new_size_url, inertia: inertia_errors(@size.errors)
    end
  end

  def update
    if @size.update(size_params)
      redirect_to size_url(@size), notice: "Size was successfully updated"
    else
      redirect_to edit_size_url(@size), inertia: inertia_errors(@size.errors)
    end
  end

  def destroy
    @size.destroy

    redirect_to sizes_url, notice: "Size was successfully destroyed"
  end

  private

  def size_params
    params.expect(size: [:value])
  end

  def set_size
    @size = Size.find(params.expect(:id))
  end
end
