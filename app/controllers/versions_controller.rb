# frozen_string_literal: true

class VersionsController < ApplicationController
  before_action :set_version, only: %i[show edit update destroy]

  def index
    @versions = Version.order(:value)

    return unless stale?(etag: [@versions, request.inertia?], last_modified: @versions.maximum(:updated_at))

    render inertia: "Versions/Index", props: {
      versions: @versions.map { |version| helpers.version_props(version) }
    }
  end

  def show
    @version = Version.includes(:products).find(params.expect(:id))

    render inertia: "Versions/Show", props: {
      version: helpers.version_props(@version),
      products: @version.products.map { |product| helpers.product_props(product) }
    }
  end

  def new
    @version = Version.new

    render inertia: "Versions/New", props: helpers.version_form_props(@version)
  end

  def edit
    render inertia: "Versions/Edit", props: helpers.version_form_props(@version)
  end

  def create
    @version = Version.new(version_params)

    respond_to do |format|
      if @version.save
        format.html { redirect_to version_url(@version), notice: "Version was successfully created" }
        format.json { render :show, status: :created, location: @version }
      else
        format.html { redirect_to new_version_url, inertia: inertia_errors(@version.errors) }
        format.json { render json: @version.errors, status: :unprocessable_content }
      end
    end
  end

  def update
    respond_to do |format|
      if @version.update(version_params)
        format.html { redirect_to version_url(@version), notice: "Version was successfully updated" }
        format.json { render :show, status: :ok, location: @version }
      else
        format.html { redirect_to edit_version_url(@version), inertia: inertia_errors(@version.errors) }
        format.json { render json: @version.errors, status: :unprocessable_content }
      end
    end
  end

  def destroy
    @version.destroy

    respond_to do |format|
      format.html { redirect_to versions_url, notice: "Version was successfully destroyed" }
      format.json { head :no_content }
    end
  end

  private

  def version_params
    params.fetch(:version, {}).permit(:value)
  end

  def set_version
    @version = Version.find(params.expect(:id))
  end
end
