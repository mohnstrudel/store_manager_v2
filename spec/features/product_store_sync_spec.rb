# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Product Store Sync" do
  before { sign_in_as_admin }

  scenario "displays store sync button on product show page", :js do # rubocop:todo RSpec/MultipleExpectations
    product = create(:product)

    visit product_path(product)

    expect(page).to have_content("Store Sync")
    expect(page).to have_css("a[data-controller='modal-trigger']")
  end

  scenario "opens store sync modal when button is clicked", :js do # rubocop:todo RSpec/MultipleExpectations
    product = create(:product)

    visit product_path(product)

    click_link "Store Sync"

    expect(page).to have_css("dialog#product-sync-modal")
    expect(page).to have_content("Store Synchronization")
  end

  scenario "shows publish button when product is not published to Shopify", :js do # rubocop:todo RSpec/MultipleExpectations
    product = build(:product)
    product.save(validate: false)

    visit product_path(product)
    click_link "Store Sync"

    expect(page).to have_button("Publish to Shopify")
    expect(page).not_to have_button("Push updates to Shopify")
    expect(page).not_to have_button("Pull updates from Shopify")
  end

  scenario "shows push and pull buttons when product is published to Shopify", :js do # rubocop:todo RSpec/MultipleExpectations
    product = create(:product)

    visit product_path(product)
    click_link "Store Sync"

    expect(page).to have_button("Push updates to Shopify")
    expect(page).to have_button("Pull updates from Shopify")
    expect(page).not_to have_button("Publish to Shopify")
  end

  scenario "displays push and pull times when available", :js do # rubocop:todo RSpec/MultipleExpectations
    product = create(:product)
    product.shopify_info.update(
      push_time: 2.days.ago,
      pull_time: 1.day.ago
    )

    visit product_path(product)
    click_link "Store Sync"

    expect(page).to have_content(/Pushed:/)
    expect(page).to have_content(/Pulled:/)
  end

  scenario "displays not yet pushed message when push_time is blank", :js do # rubocop:todo RSpec/MultipleExpectations
    product = create(:product)
    product.shopify_info.update(push_time: nil)

    visit product_path(product)
    click_link "Store Sync"

    expect(page).to have_content("Not yet pushed")
  end

  scenario "does not highlight push time in red when it is current", :js do # rubocop:todo RSpec/MultipleExpectations
    product = create(:product)
    product.shopify_info.update(
      push_time: 1.day.ago,
      pull_time: 3.days.ago
    )
    # Set updated_at to be older than push_time so it's not outdated
    product.update_column(:updated_at, 2.days.ago) # rubocop:disable Rails/SkipsModelValidations

    visit product_path(product)
    click_link "Store Sync"

    within("dialog#product-sync-modal") do
      expect(page).to have_css("h4.font-medium", text: /Pushed:/)
      expect(page).not_to have_css("h4.text-red-600", text: /Pushed:/)
    end
  end

  scenario "closes modal when close button is clicked", :js do # rubocop:todo RSpec/MultipleExpectations
    product = create(:product)

    visit product_path(product)
    click_link "Store Sync"
    expect(page).to have_css("dialog#product-sync-modal")

    find("button[aria-label='Close']").click

    expect(page).not_to have_css("dialog#product-sync-modal[open]")
  end

  scenario "closes modal after push action and can be reopened", :js do # rubocop:todo RSpec/MultipleExpectations
    product = create(:product)
    allow(Shopify::UpdateProductJob).to receive(:perform_later)

    visit product_path(product)

    # Open the modal
    click_link "Store Sync"
    expect(page).to have_content("Store Synchronization")

    # Click push action
    click_button "Push updates to Shopify"

    # Modal should close (content no longer visible)
    expect(page).not_to have_content("Store Synchronization")

    # Notice should be displayed
    expect(page).to have_content("Product updates are being pushed to Shopify")

    # Modal should be able to be opened again without errors
    click_link "Store Sync"
    expect(page).to have_content("Store Synchronization")
  end

  scenario "closes modal after publish action and can be reopened", :js do # rubocop:todo RSpec/MultipleExpectations
    product = build(:product)
    product.save(validate: false)
    allow(Shopify::CreateProductJob).to receive(:perform_later)

    visit product_path(product)

    # Open the modal
    click_link "Store Sync"
    expect(page).to have_content("Store Synchronization")

    # Click publish action
    click_button "Publish to Shopify"

    # Modal should close (content no longer visible)
    expect(page).not_to have_content("Store Synchronization")

    # Notice should be displayed
    expect(page).to have_content("Product is being published to Shopify")

    # Modal should be able to be opened again without errors
    click_link "Store Sync"
    expect(page).to have_content("Store Synchronization")
  end

  scenario "closes modal after pull action and can be reopened", :js do # rubocop:todo RSpec/MultipleExpectations
    product = create(:product)
    allow(Shopify::PullProductJob).to receive(:perform_later)

    visit product_path(product)

    # Open the modal
    click_link "Store Sync"
    expect(page).to have_content("Store Synchronization")

    # Click pull action
    click_button "Pull updates from Shopify"

    # Modal should close (content no longer visible)
    expect(page).not_to have_content("Store Synchronization")

    # Notice should be displayed
    expect(page).to have_content("Product is being pulled from Shopify")

    # Modal should be able to be opened again without errors
    click_link "Store Sync"
    expect(page).to have_content("Store Synchronization")
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

      expect(page).to have_link("Pull Last 50 Products")
      expect(page).to have_link("Pull Everything")
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

      expect(page).to have_link("Pull Last 50 Products", href: "/products/pull?limit=50")
    end

    scenario "navigates to pull products without limit when Pull Everything is clicked", :js do # rubocop:todo RSpec/MultipleExpectations
      create_list(:product, 3)

      visit products_path
      click_link "Store Sync"

      expect(page).to have_link("Pull Everything", href: "/products/pull")
    end

    scenario "navigates to jobs statuses page when Track Jobs Progress is clicked", :js do # rubocop:todo RSpec/MultipleExpectations
      create_list(:product, 3)

      visit products_path
      click_link "Store Sync"

      expect(page).to have_link("Track Jobs Progress", href: "/jobs/statuses")
    end
  end
end
