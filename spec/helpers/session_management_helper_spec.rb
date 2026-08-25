# frozen_string_literal: true

require "rails_helper"

RSpec.describe Helpers::SessionManagement do
  after { Current.reset }

  it "signs the requested user into a feature session" do
    user = create(:user, :manager)
    harness = Class.new do
      include Helpers::SessionManagement

      attr_reader :browser_user

      def feature_test? = true

      def sign_in_browser(user)
        @browser_user = user
      end
    end.new

    harness.sign_in(user)

    expect(harness.browser_user).to eq(user)
  end
end
