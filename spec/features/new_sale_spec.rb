# frozen_string_literal: true

require "rails_helper"

feature "New sale form" do
  before { sign_in_as_admin }

  scenario "keeps a Sale row through Variant validation, then links the saved Sale to stock", :js do # rubocop:disable RSpec/MultipleExpectations
    customer = create(:customer)
    product = create(:product, title: "Variant Sale Product")
    variant = create(:variant, product:, size: create(:size, value: "Large"))
    supplier = create(:supplier, title: "Linked Supplier")
    warehouse = create(:warehouse, name: "Linked Warehouse")
    purchase = create(:purchase, product:, variant:, supplier:, amount: 1)
    create(:purchase_item, purchase:, warehouse:)

    visit new_sale_path

    choose "Processing"
    choose_react_select(customer.email, from: "Customer")
    click_button "Add Product"

    within ".sales_form__product_fields" do
      choose_react_select(product.title, from: "Product")
      expect(page).to have_field("Variant")
      expect(find("input[name='sale_items[0][variant_id]']", visible: false).value).to eq("")
      fill_in "Amount", with: "1"
      fill_in "Price", with: "100"
    end

    click_button "Create Sale"

    expect(page).to have_current_path(new_sale_path, ignore_query: true)
    within ".sales_form__product_fields" do
      expect(page).to have_content("must be selected")
      expect(find_field("Amount").value).to eq("1")
      choose_react_select(variant.title, from: "Variant")
    end

    expect(Sale.count).to eq(0)

    click_button "Create Sale"

    expect(page).to have_content("Sale was successfully created")
    expect(Sale.count).to eq(1)
    expect(Sale.last.sale_items.sole.variant).to eq(variant)
    expect(page).to have_content(product.full_title)
    expect(page).to have_content(supplier.title)
    expect(page).to have_content(warehouse.name)
    expect(page).not_to have_content(/MISSING \d+ PURCHASE/)
  end
end
