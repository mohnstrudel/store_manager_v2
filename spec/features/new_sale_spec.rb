# frozen_string_literal: true

require "rails_helper"

feature "New sale form" do
  before { sign_in_as_admin }
  after { log_out }

  scenario "shows validation errors when submitted untouched", :js do
    visit new_sale_path

    expect(page).to have_button("Create Sale")

    expect {
      click_button "Create Sale"
    }.not_to change(Sale, :count)

    expect(page).to have_current_path(new_sale_path, ignore_query: true)
    expect(page).to have_content("Fix errors and try again")
  end

  scenario "keeps a Sale row visible when explicit Variant validation fails", :js do # rubocop:disable RSpec/MultipleExpectations
    customer = create(:customer)
    product = create(:product, title: "Variant Sale Product")
    variant = create(:variant, product:, size: create(:size, value: "Large"))

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

    expect {
      click_button "Create Sale"
    }.not_to change(Sale, :count)

    expect(page).to have_current_path(new_sale_path, ignore_query: true)
    within ".sales_form__product_fields" do
      expect(page).to have_content("must be selected")
      expect(find_field("Amount").value).to eq("1")
      choose_react_select(variant.title, from: "Variant")
    end

    expect {
      click_button "Create Sale"
    }.to change(Sale, :count).by(1)

    expect(Sale.last.sale_items.sole.variant).to eq(variant)
  end
end
