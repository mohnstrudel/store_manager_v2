# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Products index buttons" do
  before { sign_in_as_admin }

  scenario "shows the legacy sync and create actions", :js do
    product = create(:product)
    allow(Config).to receive(:shopify_products_sync_at).and_return(Time.zone.local(2026, 5, 19, 11, 53))

    visit products_path

    expect(page).to have_button("Store Sync")
    expect(page).to have_link("Add New Record", href: new_product_path)
    expect(page).to have_link("Edit", href: edit_product_path(product))

    click_button "Store Sync"

    expect(page).to have_content("Last fetched at 19 May at 11:53")
  end
end
