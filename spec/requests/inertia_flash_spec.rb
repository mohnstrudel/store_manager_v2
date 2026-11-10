# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Inertia flash" do
  before { sign_in_as_admin }

  it "delivers a redirect notice on a partial reload that lists no shared props" do
    brand = create(:brand)

    patch brand_path(brand), params: {brand: {title: "Moonbow"}}
    follow_redirect!(headers: partial_reload_headers("Brands/Show", "brand"))

    expect_inertia.to have_exact_flash(notice: "Brand was successfully updated")
  end

  it "delivers the link of a structured notice" do
    allow(Variant::AssignmentBackfillJob).to receive(:perform_later)

    post broken_sales_backfill_path
    follow_redirect!(headers: partial_reload_headers("BrokenSales/Index", "issues"))

    expect(inertia.flash[:notice]).to include(
      message: start_with("Started. You'll get a notification"),
      link: include(label: "jobs dashboard", href: "/jobs/statuses")
    )
  end

  it "delivers the notice once" do
    patch brand_path(create(:brand)), params: {brand: {title: "Moonbow"}}
    follow_redirect!

    get brands_path

    expect(inertia.flash).to be_empty
  end

  def partial_reload_headers(component, only)
    {
      "X-Inertia" => "true",
      "X-Inertia-Partial-Component" => component,
      "X-Inertia-Partial-Data" => only
    }
  end
end
