# frozen_string_literal: true

module Helpers
  module SessionManagement
    def log_out
      Current.session&.destroy!
      if feature_test?
        Capybara.reset_sessions!
      else
        cookies.delete(:session_id)
      end
    end

    def feature_test?
      @is_feature ||= defined?(page) && page.driver.is_a?(Capybara::Cuprite::Driver)
    end

    def sign_in_as_admin
      sign_in admin
    end

    def sign_in(user)
      Current.session = user.sessions.create!
      if feature_test?
        set_session_cookie_in_browser(Current.session.id)
      else
        set_session_cookie_in_request(Current.session.id)
      end
    end

    def set_session_cookie_in_browser(id)
      page.driver.set_cookie(
        "session_id",
        Rack::Utils.escape(signed_session_cookie(id)),
        domain: page.server.host,
        path: "/",
        httponly: true
      )
    end

    def signed_session_cookie(id)
      ActionDispatch::TestRequest.create.cookie_jar.tap { |cookie_jar|
        cookie_jar.signed[:session_id] = id
      }[:session_id]
    end

    def set_session_cookie_in_request(id)
      cookies[:session_id] = signed_session_cookie(id)
    end

    def admin
      @admin ||= create(:user, :admin)
    end
  end
end
