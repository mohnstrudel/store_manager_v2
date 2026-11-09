# frozen_string_literal: true

require "rails_helper"

RSpec.describe Helpers::SessionManagement do
  after { Current.reset }

  it "sets the signed session cookie of the requested user in the feature browser" do
    user = create(:user, :manager)
    driver = instance_double(Capybara::Cuprite::Driver, set_cookie: true)
    server = instance_double(Capybara::Server, host: "127.0.0.1")
    page = instance_double(Capybara::Session, driver:, server:)
    harness = Class.new do
      include Helpers::SessionManagement

      def initialize(page) = @page = page

      attr_reader :page

      def feature_test? = true
    end.new(page)

    harness.sign_in(user)

    expect(driver).to have_received(:set_cookie) do |name, value, options|
      expect(name).to eq("session_id")
      expect(options).to include(domain: "127.0.0.1", path: "/")
      jar = ActionDispatch::TestRequest.create("HTTP_COOKIE" => "session_id=#{value}").cookie_jar
      expect(Session.find(jar.signed[:session_id]).user).to eq(user)
    end
  end
end
