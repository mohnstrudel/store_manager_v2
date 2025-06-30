class ApplicationController < ActionController::Base
  include Authentication
  layout :choose_layout

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

  private

  def choose_layout
    authenticated? ? "application" : "unauthenticated"
  end
end
