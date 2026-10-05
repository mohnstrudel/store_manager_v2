# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Glossary" do
  describe "GET /glossary" do
    it "renders the Inertia component for an admin" do
      sign_in_as_admin

      get glossary_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Glossary/Show")
    end

    it "renders for a manager, not just admins" do
      sign_in create(:user, :manager)

      get glossary_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Glossary/Show")
    end

    it "renders for support staff, who read these words on the pages they use" do
      sign_in create(:user, :support)

      get glossary_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Glossary/Show")
    end

    it "renders for the default (guest-role) user, not gated by role at all" do
      sign_in create(:user)

      get glossary_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Glossary/Show")
    end

    it "redirects an unauthenticated visitor to sign in" do
      get glossary_path

      expect(response).to redirect_to(sign_in_path)
    end
  end
end
