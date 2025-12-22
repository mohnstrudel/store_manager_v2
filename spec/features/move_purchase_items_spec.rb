# frozen_string_literal: true
require "rails_helper"

describe "Moving purchased products between warehouses" do
  before { sign_in_as_admin }
  after { log_out }

  let(:warehouse_from) { create(:warehouse, name: "Warehouse From") }
  let!(:warehouse_to) { create(:warehouse, name: "Warehouse To") }
  let(:product) { create(:product) }
  let(:purchase) { create(:purchase, product: product) }
  let!(:purchase_items) do # rubocop:todo RSpec/LetSetup
    create_list(:purchase_item, 3, warehouse: warehouse_from, purchase: purchase)
  end

  context "when we visit warehouses index page" do
    scenario "select purchased products and move to another warehouse", :js do # rubocop:todo RSpec/MultipleExpectations
      visit warehouse_path(warehouse_from)

      # Select 2 out of 3 purchased products
      find("tbody tr:nth-child(1) input[type='checkbox']").check
      find("tbody tr:nth-child(2) input[type='checkbox']").check

      # Enable the form to be visible in the test environment
      page.execute_script("document.querySelector('.move_to_warehouse__form').style.position = 'static';")

      # Select where to move products
      slim_select("Select a warehouse", warehouse_to.name)

      click_link "Move"

      expect(page).to have_content("Success! 2 purchased products moved to: #{warehouse_to.name}", wait: 5)
      expect(page).to have_content("Items: 1")

      visit warehouse_path(warehouse_to)
      expect(page).to have_content("Items: 2")
    end
  end

  context "when we visit purchases index page" do
    scenario "select purchases and move to another warehouse", :js do # rubocop:todo RSpec/MultipleExpectations
      visit purchases_path

      # Verify that we have purchased products in the original warehouse
      expect(page).to have_content("#{warehouse_from.name}: 3")

      # Select a purchase
      find("tbody tr:nth-child(1) input[type='checkbox']").check

      # Enable the form to be visible in the test environment
      page.execute_script("document.querySelector('.move_to_warehouse__form').style.position = 'static';")

      # Select where to move purchases
      slim_select("Select a warehouse", warehouse_to.name)

      click_link "Move"

      expect(page).to have_content("Success! 3 purchased products moved to: #{warehouse_to.name}")

      # Verify the moved purchases are no longer in the original warehouse
      expect(page).to have_content("#{warehouse_to.name}: 3")

      # Visit the destination warehouse to verify the moved purchases
      visit warehouse_path(warehouse_to)
      expect(page).to have_css("tbody tr", count: 3)
    end
  end

  context "when we visit purchases show page" do
    scenario "select purchased products and move to another warehouse", :js do # rubocop:todo RSpec/MultipleExpectations
      visit purchase_path(purchase)

      # Verify that we have purchased products in the original warehouse
      expect(page).to have_content("Items: 3")
      # 3 items inside the table, 2 in two selects
      expect(page).to have_text(warehouse_from.name, count: 5)

      # Select 2 out of 3 purchased products
      find("tbody tr:nth-child(1) input[type='checkbox']").check
      find("tbody tr:nth-child(2) input[type='checkbox']").check

      # Enable the form to be visible in the test environment
      page.execute_script("document.querySelector('.move_to_warehouse__form').style.position = 'static';")

      # Select where to move products
      slim_select("Select a warehouse", warehouse_to.name)

      click_link "Move"

      expect(page).to have_content("Success! 2 purchased products moved to: #{warehouse_to.name}")

      # Verify we have the same amount of purchased products
      expect(page).to have_content("Items: 3")

      # Verify the moved purchases are no longer in the original warehouse
      # 1 time in the notice, 2 in two selects, 2 inside the table
      expect(page).to have_text(:visible, warehouse_to.name, count: 5)

      visit warehouse_path(warehouse_to)
      expect(page).to have_content("Items: 2")
    end
  end
end
