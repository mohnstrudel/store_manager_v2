# frozen_string_literal: true

class VersionsController < ApplicationController
  before_action :set_version, only: %i[show edit update destroy]

  def index
    @versions = Version.order(:value)

    return unless stale?(etag: [@versions, request.inertia?], last_modified: @versions.maximum(:updated_at))

    render_inertia "Versions/Index", serializer: Versions::IndexResource, locals: {versions: @versions}
  end

  def show
    @version = Version.includes(:products).find(params.expect(:id))

    render_inertia "Versions/Show", serializer: Versions::ShowResource, locals: {version: @version}
  end

  def new
    @version = Version.new

    render_inertia "Versions/New", serializer: Versions::FormResource, locals: {version: @version}
  end

  def edit
    render_inertia "Versions/Edit", serializer: Versions::FormResource, locals: {version: @version}
  end

  def create
    @version = Version.new(version_params)

    if @version.save
      redirect_to version_url(@version), notice: "Version was successfully created"
    else
      redirect_to new_version_url, inertia: inertia_errors(@version.errors)
    end
  end

  def update
    if @version.update(version_params)
      redirect_to version_url(@version), notice: "Version was successfully updated"
    else
      redirect_to edit_version_url(@version), inertia: inertia_errors(@version.errors)
    end
  end

  def destroy
    @version.destroy

    redirect_to versions_url, notice: "Version was successfully destroyed"
  end

  private

  def version_params
    params.fetch(:version, {}).permit(:value)
  end

  def set_version
    @version = Version.find(params.expect(:id))
  end
end
