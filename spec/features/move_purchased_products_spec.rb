require "rails_helper"

describe "Moving purchased products between warehouses" do
  let(:warehouse_from) { create(:warehouse, name: "Warehouse From") }
  let!(:warehouse_to) { create(:warehouse, name: "Warehouse To") }
  let(:product) { create(:product) }
  let(:purchase) { create(:purchase, product: product) }
  let!(:purchased_products) do
    create_list(:purchased_product, 3, warehouse: warehouse_from, purchase: purchase)
  end

  context "when we visit warehouses index page" do
    scenario "select purchased products and move to another warehouse", js: true do
      visit warehouse_path(warehouse_from)

      # Select 2 out of 3 purchased products
      find("tbody tr:nth-child(1) input[type='checkbox']").check
      find("tbody tr:nth-child(2) input[type='checkbox']").check

      # Enable the form to be visible in the test environment
      page.execute_script("document.querySelector('.move_to_warehouse__form').style.position = 'static';")

      # Select where to move products
      find(".ss-values", text: "Select a warehouse").click
      find(".ss-option", text: warehouse_to.name).click

      click_link "Move"

      expect(page).to have_content("Success! 2 purchased products moved to: #{warehouse_to.name}")
      expect(page).to have_content("Purchased Products 1")

      visit warehouse_path(warehouse_to)
      expect(page).to have_content("Purchased Products 2")
    end
  end

  context "when we visit purchases index page" do
    scenario "select purchases and move to another warehouse", js: true do
      visit purchases_path

      # Verify that we have purchased products in the original warehouse
      expect(page).to have_content("#{warehouse_from.name}: 3")

      # Select a purchase
      find("tbody tr:nth-child(1) input[type='checkbox']").check

      # Enable the form to be visible in the test environment
      page.execute_script("document.querySelector('.move_to_warehouse__form').style.position = 'static';")

      # Select where to move purchases
      find(".ss-values", text: "Select a warehouse").click
      find(".ss-option", text: warehouse_to.name).click

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
    scenario "select purchased products and move to another warehouse", js: true do
      visit purchase_path(purchase)

      # Verify that we have purchased products in the original warehouse
      expect(page).to have_content("Stored in Warehouses: 3")
      # 3 items inside the table, 1 in the select
      expect(page).to have_text(warehouse_from.name, count: 4)

      # Select 2 out of 3 purchased products
      find("tbody tr:nth-child(1) input[type='checkbox']").check
      find("tbody tr:nth-child(2) input[type='checkbox']").check

      # Enable the form to be visible in the test environment
      page.execute_script("document.querySelector('.move_to_warehouse__form').style.position = 'static';")

      # Select where to move products
      find(".ss-values", text: "Select a warehouse").click
      find(".ss-option", text: warehouse_to.name).click

      click_link "Move"

      expect(page).to have_content("Success! 2 purchased products moved to: #{warehouse_to.name}")

      # Verify we have the same amount of purchased products
      expect(page).to have_content("Stored in Warehouses: 3")

      # Verify the moved purchases are no longer in the original warehouse
      # 1 time in the notice, 1 in the select, 2 inside the table
      expect(page).to have_text(warehouse_to.name, count: 4)

      visit warehouse_path(warehouse_to)
      expect(page).to have_content("Purchased Products 2")
    end
  end
end
