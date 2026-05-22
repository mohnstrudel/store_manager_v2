# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Product Store Sync" do
  before { sign_in_as_admin }

  scenario "starts a fetch from the show page without leaving it", :js do
    product = create(:product)
    allow(Shopify::PullProductJob).to receive(:perform_later)

    visit product_path(product)
    click_button "Fetch"

    expect(page).to have_current_path(product_path(product), ignore_query: true)
    expect(page).to have_content("Product is being fetched from Shopify")
  end

  scenario "shows no fetch button when product is not linked to Shopify", :js do
    product = create(:product)
    product.shopify_info.update!(store_id: nil)

    visit product_path(product)

    expect(page).to have_no_button("Fetch")
  end
end
