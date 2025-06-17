require "rails_helper"

feature "Link sales with purchases flow" do
  let!(:product) { create(:product, title: "Test Product") }
  let!(:supplier) { create(:supplier) }
  let!(:customer) { create(:customer) }
  let!(:warehouse) { create(:warehouse, is_default: true) }

  scenario "creates a sale, links it with a purchase and verifies order items", js: true do
    # Start with creating a purchase
    # because we don't want it to be automatically linked to the sale
    visit purchases_path

    click_on "🐣 New"

    select supplier.title, from: "purchase[supplier_id]"

    fill_in "Amount", with: 5
    fill_in "Item price", with: 50

    # Fill "What did you pay in total?" field
    fill_in "purchase[payments_attributes][0][value]", with: "250"

    click_on "Create Purchase"

    # Create a sale
    expect(page).to have_content("Purchase was successfully created")

    visit sales_path

    click_on "🐣 New"

    # Set an active status so the sale will be visible in the list
    choose "Processing"
    fill_in "Total", with: 100

    # Add product to sale
    click_button "Add Product"
    select product.title, from: "sale[sale_items_attributes][1][product_id]"
    fill_in "sale[sale_items_attributes][1][qty]", with: 1
    fill_in "sale[sale_items_attributes][1][price]", with: "100.00"

    click_on "Create Sale"

    expect(page).to have_content("Sale was successfully created")

    # Verify "Sale Items List" exists
    # and that it contains the product we added to the sale
    expect(page).to have_content("Sale Items List")
    expect(page).to have_content(product.full_title)
    expect(page).to have_content(supplier.title)
    expect(page).to have_content(warehouse.name)

    # Purchased/Sold ratio is correct
    expect(page).to have_selector("mark.smaller.muted", text: "1 / 1", normalize_ws: true)
  end
end
