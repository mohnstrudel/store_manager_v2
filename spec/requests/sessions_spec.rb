# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions" do
  describe "GET /sign_in" do
    it "renders the sign-in Inertia component" do
      get sign_in_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Sessions/New")
    end

    it "passes email_address param as prop" do
      get sign_in_path, params: {email_address: "user@example.com"}

      expect_inertia.to have_props(email_address: "user@example.com")
    end

    it "redirects authenticated users to root" do
      sign_in_as_admin

      get sign_in_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /session" do
    it "creates a session and redirects on valid credentials" do
      user = create(:user)

      post session_path, params: {email_address: user.email_address, password: "password"}

      expect(response).to redirect_to(noop_path)
    end

    it "redirects back to sign in with an alert on invalid credentials" do
      post session_path, params: {email_address: "bad@example.com", password: "wrong"}

      expect(response).to redirect_to(sign_in_path)

      follow_redirect!

      expect(inertia.props[:flash][:alert]).to eq("Try another email address or password")
    end
  end

  describe "POST /log_out" do
    it "destroys the session and redirects to sign in" do
      sign_in_as_admin

      post log_out_path

      expect(response).to redirect_to(sign_in_path)
    end
  end
end
