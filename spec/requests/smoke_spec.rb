# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /_inertia_smoke" do
  before { sign_in_as_admin }

  it "renders the Hello/Index Inertia component" do
    get "/_inertia_smoke"

    expect(response).to have_http_status(:ok)
    expect_inertia.to render_component("Hello/Index")
  end

  it "shares auth and flash props" do
    get "/_inertia_smoke"

    expect_inertia.to have_props(
      auth: {user: {id: admin.id, email_address: admin.email_address, role: admin.role}}
    )
  end
end
