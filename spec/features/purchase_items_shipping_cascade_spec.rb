# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Purchase items shipping cascade editing" do
  before { sign_in_as_admin }
  after { log_out }

  let!(:warehouse) { create(:warehouse) }
  let!(:shipping_company) { create(:shipping_company, name: "Skyline") }
  let!(:purchase) { create(:purchase) }
  let!(:blank_item) do
    create(:purchase_item, purchase:, warehouse:,
      tracking_number: nil, shipping_company: nil, shipping_cost: "0")
  end

  # On the purchase show page the three shipping editors coordinate through refs:
  # opening one editor on a blank row auto-opens its siblings and saves all three
  # together via the bulk shipping_details endpoint. That ref / imperative-handle
  # cascade only runs in a real browser, so it needs a Cuprite spec.
  scenario "opening a blank row cascades the sibling editors and saves them together", :js do
    visit purchase_path(purchase)

    find("[aria-label='Edit tracking number']").trigger("click")

    # The cascade auto-opens all three editors for a blank row.
    expect(page).to have_field("Tracking number")
    expect(page).to have_field("Shipping company")
    expect(page).to have_field("Shipping cost")

    fill_in "Tracking number", with: "TRACK-77"
    select "Skyline", from: "Shipping company"
    fill_in "Shipping cost", with: "15"

    within(find_field("Tracking number").ancestor("form")) do
      click_button "Save"
    end

    expect(page).to have_text("TRACK-77")
    expect(page).to have_text("Skyline")

    blank_item.reload
    expect(blank_item.tracking_number).to eq("TRACK-77")
    expect(blank_item.shipping_company).to eq(shipping_company)
    expect(blank_item.shipping_cost).to eq(BigDecimal(15))
  end
end
