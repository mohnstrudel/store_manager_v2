# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Passwords" do
  describe "GET /passwords/new" do
    it "renders the forgot-password Inertia component" do
      get new_password_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Passwords/New")
    end

    it "passes email_address param as prop" do
      get new_password_path, params: {email_address: "user@example.com"}

      expect_inertia.to have_props(email_address: "user@example.com")
    end
  end

  describe "POST /passwords" do
    it "redirects to sign in with a notice regardless of whether the email exists" do
      post passwords_path, params: {email_address: "anyone@example.com"}

      expect(response).to redirect_to(sign_in_path)

      follow_redirect!

      expect(inertia.props[:flash][:notice]).to eq(
        "Password reset instructions sent (if user with that email address exists)"
      )
    end

    it "enqueues a reset email when the account exists" do
      user = create(:user)

      expect {
        post passwords_path, params: {email_address: user.email_address}
      }.to have_enqueued_mail(PasswordsMailer, :reset)
    end
  end

  describe "GET /passwords/:token/edit" do
    it "renders the reset-password Inertia component" do
      user = create(:user)
      token = user.password_reset_token

      get edit_password_path(token)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Passwords/Edit")
      expect_inertia.to have_props(token: token)
    end

    it "redirects to new_password with an alert on an invalid token" do
      get edit_password_path("invalid-token")

      expect(response).to redirect_to(new_password_path)

      follow_redirect!

      expect(inertia.props[:flash][:alert]).to eq("Password reset link is invalid or has expired")
    end
  end

  describe "PATCH /passwords/:token" do
    it "updates the password and redirects to sign in" do
      user = create(:user)
      token = user.password_reset_token

      patch password_path(token), params: {password: "newpassword", password_confirmation: "newpassword"}

      expect(response).to redirect_to(sign_in_path)

      follow_redirect!

      expect(inertia.props[:flash][:notice]).to eq("Password has been reset")
    end

    it "redirects back with an alert when passwords do not match" do
      user = create(:user)
      token = user.password_reset_token

      patch password_path(token), params: {password: "newpassword", password_confirmation: "mismatch"}

      expect(response).to redirect_to(edit_password_path(token))

      follow_redirect!

      expect(inertia.props[:flash][:alert]).to eq("Passwords did not match")
    end
  end
end
