require "rails_helper"

describe "Moving purchased products between warehouses" do
  let!(:warehouse_from) { create(:warehouse, name: "Warehouse From") }
  let!(:warehouse_to) { create(:warehouse, name: "Warehouse To") }
  let!(:product) { create(:product) }
  let!(:purchased_products) do
    create_list(:purchased_product, 3, warehouse: warehouse_from, purchase: create(:purchase, product: product))
  end

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
