# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication
  include Authorization
  inertia_share do
    {
      auth: {user: current_user&.slice(:id, :email_address, :role)},
      flash: {notice: flash.notice, alert: flash.alert},
      csrf_token: form_authenticity_token
    }
  end

  private

  def pagination_props(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      limit: collection.limit_value
    }
  end

  if Rails.env.development?
    before_action do
      ActiveStorage::Current.url_options = {host: "http://localhost:3000"}
    end

    around_action :n_plus_one_detection

    def n_plus_one_detection
      Prosopite.scan
      yield
    ensure
      Prosopite.finish
    end
  end
end
