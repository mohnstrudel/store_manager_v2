# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Jobs dashboard" do
  it "hides the dashboard from visitors who are not signed in" do
    get "/jobs/"

    expect(response).to have_http_status(:not_found)
  end

  it "hides the dashboard from guests" do
    sign_in create(:user, role: :guest)

    get "/jobs/"

    expect(response).to have_http_status(:not_found)
  end

  %i[admin manager support].each do |role|
    it "opens the dashboard for #{role}s" do
      sign_in create(:user, role:)

      get "/jobs/"

      expect(response).to have_http_status(:ok)
    end
  end
end
