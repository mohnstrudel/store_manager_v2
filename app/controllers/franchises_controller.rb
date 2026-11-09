# frozen_string_literal: true

class FranchisesController < ApplicationController
  before_action :set_franchise, only: %i[show edit update destroy]

  def index
    @franchises = Franchise.order(:title)

    return unless stale?(etag: [@franchises], last_modified: @franchises.maximum(:updated_at))

    render_inertia "Franchises/Index", serializer: Franchises::IndexResource, locals: {franchises: @franchises}
  end

  def show
    @franchise = Franchise.includes(:products).find(params.expect(:id))

    render_inertia "Franchises/Show", serializer: Franchises::ShowResource, locals: {franchise: @franchise}
  end

  def new
    @franchise = Franchise.new

    render_inertia "Franchises/New", serializer: Franchises::NewResource, locals: {franchise: @franchise}
  end

  def edit
    render_inertia "Franchises/Edit", serializer: Franchises::EditResource, locals: {franchise: @franchise}
  end

  def create
    @franchise = Franchise.new(franchise_params)

    if @franchise.save
      redirect_to franchise_url(@franchise), notice: "Franchise was successfully created"
    else
      redirect_to new_franchise_url, inertia: inertia_errors(@franchise.errors)
    end
  end

  def update
    if @franchise.update(franchise_params)
      redirect_to franchise_url(@franchise), notice: "Franchise was successfully updated"
    else
      redirect_to edit_franchise_url(@franchise), inertia: inertia_errors(@franchise.errors)
    end
  end

  def destroy
    @franchise.destroy

    redirect_to franchises_url, notice: "Franchise was successfully destroyed"
  end

  private

  def franchise_params
    params.expect(franchise: [:title])
  end

  def set_franchise
    @franchise = Franchise.find(params.expect(:id))
  end
end
