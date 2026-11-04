# frozen_string_literal: true

class ColorsController < ApplicationController
  before_action :set_color, only: %i[show edit update destroy]

  def index
    @colors = Color.order(:value)

    return unless stale?(etag: [@colors, request.inertia?], last_modified: @colors.maximum(:updated_at))

    render_inertia "Colors/Index", serializer: Colors::IndexResource, locals: {colors: @colors}
  end

  def show
    @color = Color.includes(:products).find(params.expect(:id))

    render_inertia "Colors/Show", serializer: Colors::ShowResource, locals: {color: @color}
  end

  def new
    @color = Color.new

    render_inertia "Colors/New", serializer: Colors::NewResource, locals: {color: @color}
  end

  def edit
    render_inertia "Colors/Edit", serializer: Colors::EditResource, locals: {color: @color}
  end

  def create
    @color = Color.new(color_params)

    if @color.save
      redirect_to color_url(@color), notice: "Color was successfully created"
    else
      redirect_to new_color_url, inertia: inertia_errors(@color.errors)
    end
  end

  def update
    if @color.update(color_params)
      redirect_to color_url(@color), notice: "Color was successfully updated"
    else
      redirect_to edit_color_url(@color), inertia: inertia_errors(@color.errors)
    end
  end

  def destroy
    @color.destroy

    redirect_to colors_url, notice: "Color was successfully destroyed"
  end

  private

  def color_params
    params.expect(color: [:value])
  end

  def set_color
    @color = Color.find(params.expect(:id))
  end
end
