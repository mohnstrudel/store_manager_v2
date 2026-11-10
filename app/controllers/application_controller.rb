# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication
  include Authorization
  include Alba::Inertia::Controller

  add_flash_types :success

  etag { inertia_configuration.version }

  inertia_share do
    SharedPropsResource.new({
      breadcrumb: helpers.breadcrumb_title,
      user: current_user,
      csrf_token: form_authenticity_token
    }).serializable_hash
  end

  private

  def inertia_errors(model_errors)
    {errors: model_errors.to_hash.transform_values(&:to_sentence)}
  end

  public

  if Rails.env.development?
    before_action do
      ActiveStorage::Current.url_options = {host: "http://localhost:3000"}
    end
  end

  if Rails.env.local?
    around_action :n_plus_one_detection, if: -> { request.get? || request.head? }

    def n_plus_one_detection
      Prosopite.scan
      yield
    ensure
      Prosopite.finish
    end
  end
end
