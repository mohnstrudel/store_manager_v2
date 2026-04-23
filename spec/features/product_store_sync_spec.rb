# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Product Store Sync" do
  before { sign_in_as_admin }

  scenario "shows only pull action on product show page for linked products", :js do # rubocop:todo RSpec/MultipleExpectations
    product = create(:product)

    visit product_path(product)

    expect(page).to have_link("Pull")
    expect(page).to have_no_link("Push")
    expect(page).not_to have_content("Store Sync")
  end

  scenario "shows no push when product is not published to Shopify", :aggregate_failures, :js do
    product = create(:product)
    product.shopify_info.update!(store_id: nil, push_time: nil)

    visit product_path(product)

    expect(page).to have_no_link("Push")
    expect(page).to have_no_link("Pull")
  end

  scenario "starts a pull from the show page without leaving it", :js do # rubocop:todo RSpec/MultipleExpectations
    product = create(:product)
    allow(Shopify::PullProductJob).to receive(:perform_later)

    visit product_path(product)

    click_link "Pull"

    expect(page).to have_current_path(product_path(product), ignore_query: true)
    expect(page).to have_content("Product is being pulled from Shopify")
  end

  context "when on products index page" do
    scenario "displays bulk store sync modal on index page", :js do # rubocop:todo RSpec/MultipleExpectations
      create_list(:product, 3)

      visit products_path

      expect(page).to have_content("Store Sync")
      click_link "Store Sync"

      expect(page).to have_css("dialog#products-index-sync-modal")
      expect(page).to have_content("Products Synchronization")
    end

    scenario "shows bulk sync options in modal", :js do # rubocop:todo RSpec/MultipleExpectations
      create_list(:product, 3)

      visit products_path
      click_link "Store Sync"

      expect(page).to have_button("Pull Last 50 Products")
      expect(page).to have_button("Pull Everything")
      expect(page).to have_link("Track Jobs Progress")
    end

    scenario "displays last sync time when available", :js do # rubocop:todo RSpec/MultipleExpectations
      allow(Config).to receive(:shopify_products_sync_time).and_return("2026-01-05 10:00")
      create_list(:product, 3)

      visit products_path
      click_link "Store Sync"

      expect(page).to have_content("Last sync: 2026-01-05 10:00")
    end

    scenario "navigates to pull products with limit when Pull Last 50 is clicked", :js do # rubocop:todo RSpec/MultipleExpectations
      create_list(:product, 3)

      visit products_path
      click_link "Store Sync"

      expect(page).to have_button("Pull Last 50 Products")
    end

    scenario "navigates to pull products without limit when Pull Everything is clicked", :js do # rubocop:todo RSpec/MultipleExpectations
      create_list(:product, 3)

      visit products_path
      click_link "Store Sync"

      expect(page).to have_button("Pull Everything")
    end

    scenario "navigates to jobs statuses page when Track Jobs Progress is clicked", :js do # rubocop:todo RSpec/MultipleExpectations
      create_list(:product, 3)

      visit products_path
      click_link "Store Sync"

      expect(page).to have_link("Track Jobs Progress", href: "/jobs/statuses")
    end

    scenario "keeps the page clickable after starting a bulk pull", :js do # rubocop:todo RSpec/MultipleExpectations
      create_list(:product, 3)
      allow(Shopify::PullProductsJob).to receive(:perform_later)

      visit products_path
      click_link "Store Sync"

      click_button "Pull Last 50 Products"

      expect(page).to have_current_path(products_path, ignore_query: true)
      expect(page).not_to have_css("dialog#products-index-sync-modal[open]")

      click_link "Store Sync"
      expect(page).to have_css("dialog#products-index-sync-modal[open]")
    end
  end
end
