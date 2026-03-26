# frozen_string_literal: true

require "rails_helper"

RSpec.describe SignupsController, type: :controller do
  describe "GET #new" do
    it "renders the signup form" do
      get :new

      expect(response).to be_successful
      expect(assigns[:user]).to be_a_new(User)
    end
  end

  describe "POST #create" do
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

    it "creates a user and redirects after signup" do
      expect {
        post :create, params: valid_params
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(noop_path)
      expect(flash[:notice]).to include("Account for new@example.com was successfully created")
    end

    it "re-renders the form on failure" do
      expect {
        post :create, params: valid_params.deep_merge(user: {password_confirmation: "nope"})
      }.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
