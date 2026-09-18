# frozen_string_literal: true

require "rails_helper"

feature "Link sales with purchases flow" do
  before { sign_in_as_admin }
  after { log_out }

  let!(:product) { create(:product, title: "Test Product") }
  let!(:supplier) { create(:supplier) }
  let!(:customer) { create(:customer) } # rubocop:todo RSpec/LetSetup
  let!(:warehouse) { create(:warehouse, is_default: true) }

  # rubocop:todo RSpec/MultipleExpectations
  scenario "creates a sale, links it with a purchase and verifies order items", :js do
    # rubocop:enable RSpec/MultipleExpectations
    visit purchases_path

    click_on "Add New Record"

    choose_react_select(product.title, from: "Product")
    choose_react_select(supplier.title, from: "Supplier")

    fill_in "Amount", with: 5
    fill_in "Item price", with: 50

    click_on "Create Purchase"

    expect(page).to have_css("#payment_amount", wait: 10)
    fill_in "payment_amount", with: "250"
    click_button "Add payment"

    expect(page).to have_content("Payment was successfully created")

    visit sales_path

    click_on "Add New Record"

    choose "Processing"

    choose_react_select(customer.email, from: "Customer")
    fill_in "Total", with: 100

    click_button "Add Product"
    expect(page).to have_css(".sales_form__product_fields")
    choose_react_select(product.title, from: "Product")
    fill_in "sale_items[0][qty]", with: 1
    fill_in "sale_items[0][price]", with: "100.00"

    click_on "Create Sale"

    expect(page).to have_content("Sale was successfully created")

    expect(page).to have_content(product.full_title)
    expect(page).to have_content(supplier.title)
    expect(page).to have_content(warehouse.name)

    expect(page).not_to have_content(/MISSING \d+ PURCHASE/)
  end
end
