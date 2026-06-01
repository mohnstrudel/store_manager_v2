# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Signups" do
  describe "GET /sign_up/new" do
    it "renders the sign-up Inertia component" do
      get new_sign_up_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Signups/New")
    end

    it "redirects authenticated users to root" do
      sign_in_as_admin

      get new_sign_up_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /sign_up" do
    let(:valid_params) do
      {
        user: {
          email_address: "new@example.com",
          password: "password123",
          password_confirmation: "password123",
          first_name: "New",
          last_name: "User",
          role: "guest"
        }
      }
    end

    it "creates a user and redirects to noop" do
      expect {
        post sign_up_path, params: valid_params
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(noop_path)

      follow_redirect!

      expect(inertia.props[:flash][:notice]).to eq("Account for new@example.com was successfully created")
    end

    it "redirects back to the signup form with errors on invalid params" do
      post sign_up_path, params: valid_params.deep_merge(user: {password_confirmation: "nope"})

      expect(response).to redirect_to(new_sign_up_path)

      follow_redirect!

      expect_inertia.to render_component("Signups/New")
      expect(inertia.props[:errors][:password_confirmation]).to be_present
    end
  end
end
