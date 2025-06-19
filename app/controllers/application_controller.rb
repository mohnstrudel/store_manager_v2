class ApplicationController < ActionController::Base
  include Authentication

  if Rails.env.production?
    http_basic_authenticate_with(
      name: Rails.application.credentials.dig(:basic_auth, :log),
      password: Rails.application.credentials.dig(:basic_auth, :pas),
      except: "process_order"
    )
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
