# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users" do
  before { sign_in_as_admin }

  describe "GET /users/:id/edit" do
    it "renders the edit Inertia component with user props" do
      user = create(:user)

      get edit_user_path(user)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Users/Edit")
      expect(inertia.props[:user][:id]).to eq(user.id)
      expect(inertia.props[:user][:email_address]).to eq(user.email_address)
    end

    it "includes role options" do
      user = create(:user)

      get edit_user_path(user)

      expect(inertia.props[:role_options]).to be_present
    end
  end

  describe "PATCH /users/:id" do
    it "updates the user and redirects to the show page" do
      user = create(:user, first_name: "Old")

      patch user_path(user), params: {user: {first_name: "New", email_address: user.email_address}}

      expect(response).to redirect_to(user_path(user))
      expect(user.reload.first_name).to eq("New")
    end

    it "redirects back to edit with errors on invalid email" do
      user = create(:user)

      patch user_path(user), params: {user: {email_address: ""}}

      expect(response).to redirect_to(edit_user_path(user))

      follow_redirect!

      expect_inertia.to render_component("Users/Edit")
      expect(inertia.props[:errors][:email_address]).to be_present
    end
  end

  describe "DELETE /users/:id" do
    it "destroys the user and redirects to the index" do
      user = create(:user)

      delete user_path(user)

      expect(response).to redirect_to(users_path)
      expect(User.exists?(user.id)).to be(false)
    end
  end
end
