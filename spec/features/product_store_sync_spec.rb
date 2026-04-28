# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Product Store Sync" do
  before { sign_in_as_admin }

  scenario "shows only fetch action on product show page for linked products", :js do # rubocop:todo RSpec/MultipleExpectations
    product = create(:product)

    visit product_path(product)

    expect(page).to have_link("Fetch")
    expect(page).to have_css("menu.nav_menu a.btn-rounded svg")
    expect(page).to have_no_link("Push")
    expect(page).not_to have_content("Store Sync")
  end

  scenario "shows no push when product is not published to Shopify", :aggregate_failures, :js do
    product = create(:product)
    product.shopify_info.update!(store_id: nil, push_time: nil)

    visit product_path(product)

    expect(page).to have_no_link("Push")
    expect(page).to have_no_link("Fetch")
  end

  scenario "starts a fetch from the show page without leaving it", :js do # rubocop:todo RSpec/MultipleExpectations
    product = create(:product)
    allow(Shopify::PullProductJob).to receive(:perform_later)

    visit product_path(product)

    click_link "Fetch"

    expect(page).to have_current_path(product_path(product), ignore_query: true)
    expect(page).to have_content("Product is being fetched from Shopify")
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

      expect(page).to have_button("Fetch Last 100 Products")
      expect(page).to have_button("Fetch Everything")
      expect(page).to have_link("Track Jobs Progress")
      expect(page).to have_css("menu.flex.flex-col.gap-4 li:nth-child(1) button.btn-blue", text: "Fetch Everything")
    end

    scenario "displays last fetched time when available", :js do # rubocop:todo RSpec/MultipleExpectations
      allow(Config).to receive(:shopify_products_sync_at).and_return(Time.zone.local(2026, 1, 5, 10, 0))
      create_list(:product, 3)

      visit products_path
      expect(page).to have_content("Last fetched at 5 January at 10:00")
    end

    scenario "navigates to fetch products with limit when Fetch Last 100 is clicked", :js do # rubocop:todo RSpec/MultipleExpectations
      create_list(:product, 3)

      visit products_path
      click_link "Store Sync"

      expect(page).to have_button("Fetch Last 100 Products")
      expect(page).to have_button("Fetch Everything")
    end

    scenario "navigates to fetch products without limit when Fetch Everything is clicked", :js do # rubocop:todo RSpec/MultipleExpectations
      create_list(:product, 3)

      visit products_path
      click_link "Store Sync"

      expect(page).to have_button("Fetch Everything")
    end

    scenario "navigates to jobs statuses page when Track Jobs Progress is clicked", :js do # rubocop:todo RSpec/MultipleExpectations
      create_list(:product, 3)

      visit products_path
      click_link "Store Sync"

      expect(page).to have_link("Track Jobs Progress", href: "/jobs/statuses")
    end

    scenario "keeps the page clickable after starting a bulk fetch", :js do # rubocop:todo RSpec/MultipleExpectations
      create_list(:product, 3)
      allow(Shopify::PullProductsJob).to receive(:perform_later)

      visit products_path
      click_link "Store Sync"

      click_button "Fetch Last 100 Products"

      expect(page).to have_current_path(products_path, ignore_query: true)
      expect(page).not_to have_css("dialog#products-index-sync-modal[open]")

      click_link "Store Sync"
      expect(page).to have_css("dialog#products-index-sync-modal[open]")
    end

    scenario "closes when clicking outside the modal", :js do # rubocop:todo RSpec/MultipleExpectations
      create_list(:product, 3)

      visit products_path
      click_link "Store Sync"

      page.execute_script("document.querySelector('#products-index-sync-modal').dispatchEvent(new MouseEvent('click', { bubbles: true }))")

      expect(page).not_to have_css("dialog#products-index-sync-modal[open]")
    end
  end
end
