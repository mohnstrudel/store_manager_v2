# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication
  include Authorization
  inertia_share do
    {
      breadcrumb: helpers.breadcrumb_title,
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

  def media_props(media)
    return unless media.image.attached?

    {
      id: media.id,
      alt: media.alt.to_s,
      position: media.position,
      preview_url: url_for(media.image.representation(:preview)),
      thumb_url: url_for(media.image.representation(:thumb))
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
