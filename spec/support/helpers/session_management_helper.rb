# frozen_string_literal: true
module Helpers
  module SessionManagement
    def sign_in(user)
      Current.session = user.sessions.create!
      if feature_test?
        sign_in_browser_as_admin
      else
        set_session_cookie_in_request(Current.session.id)
      end
    end

    def log_out
      Current.session&.destroy!
      if feature_test?
        page.driver.clear_cookies
      else
        cookies.delete(:session_id)
      end
    end

    def admin
      @admin ||= create(:user, :admin)
    end

    def sign_in_as_admin
      sign_in admin
    end

    def feature_test?
      @is_feature ||= defined?(page) && page.driver.respond_to?(:browser)
    end

    def sign_in_browser_as_admin
      sign_in_browser(admin)
    end

    def sign_in_browser(user)
      visit sign_in_path
      fill_in "email_address", with: user.email_address
      fill_in "password", with: "password"
      click_on "Sign in"
      expect(page).to have_current_path(noop_path)
    end

    def set_session_cookie_in_request(id)
      ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
        cookie_jar.signed[:session_id] = id
        cookies[:session_id] = cookie_jar[:session_id]
      end
    end
  end
end
