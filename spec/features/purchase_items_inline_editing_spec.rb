# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Purchase items inline editing" do
  before { sign_in_as_admin }
  after { log_out }

  let!(:warehouse) { create(:warehouse) }
  let!(:shipping_company) { create(:shipping_company, name: "Skyline") }
  let!(:purchase) { create(:purchase) }
  let!(:purchase_item) { create(:purchase_item, purchase:, warehouse:) }

  # Component tests cover client-side validation and interaction logic.
  # This spec covers the onError path from the server — Inertia's redirect-with-errors
  # cycle can only be tested with a real Rails response.
  scenario "shows server validation errors without a full-page reload", :js do
    visit warehouse_path(warehouse)

    find("[aria-label='Edit tracking number']").trigger("click")

    fill_in "Tracking number", with: "TRACK-99"
    # Leave shipping company empty — model validation requires it when tracking is present

    within(find_field("Tracking number").ancestor("form")) do
      click_button "Save"
    end

    expect(page).to have_text("Shipping company is required")
    expect(page).to have_field("Tracking number")
    expect(page).to have_current_path(warehouse_path(warehouse))
  end
end
