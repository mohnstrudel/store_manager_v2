# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating a product with a purchase" do
  before { sign_in_as_admin }
  after { log_out }

  scenario "creates both records from the new product form", :js do # rubocop:todo RSpec/MultipleExpectations
    franchise = create(:franchise)
    shape = create(:shape)
    supplier = create(:supplier)
    warehouse = create(:warehouse, is_default: true)

    visit new_product_path

    fill_in "Title", with: "Product With Purchase"
    fill_in "SKU", with: "product-with-initial-purchase"

    franchise_select = find("select[name='product[franchise_id]']", visible: :all)
    page.execute_script("arguments[0].value = arguments[1]", franchise_select, franchise.id.to_s)

    shape_select = find("select[name='product[shape_id]']", visible: :all)
    page.execute_script("arguments[0].value = arguments[1]", shape_select, shape.id.to_s)

    click_button "Add Purchase"

    supplier_select = find("select[name='purchase[supplier_id]']", visible: :all)
    page.execute_script("arguments[0].value = arguments[1]", supplier_select, supplier.id.to_s)

    fill_in "Item price", with: "15"
    fill_in "Amount", with: "2"
    fill_in "What did you pay in total?", with: "30"

    warehouse_select = find("select[name='purchase[warehouse_id]']", visible: :all)
    page.execute_script("arguments[0].value = arguments[1]", warehouse_select, warehouse.id.to_s)

    click_button "Create Product"

    created_product = Product.find_by!(sku: "product-with-initial-purchase")
    purchase = created_product.purchases.last

    expect(page).to have_current_path(product_path(created_product))
    expect(page).to have_content("Product was successfully created")
    expect(purchase).to be_present
    expect(purchase.supplier).to eq(supplier)
    expect(purchase.purchase_items.count).to eq(2)
    expect(purchase.purchase_items.pluck(:warehouse_id).uniq).to eq([warehouse.id])
    expect(purchase.payments.pluck(:value)).to eq([BigDecimal(30)])
  end

  scenario "re-renders with purchase field errors when only part of it is filled in", :js do # rubocop:disable RSpec/MultipleExpectations
    franchise = create(:franchise)
    shape = create(:shape)
    create(:warehouse, is_default: true)

    visit new_product_path

    fill_in "Title", with: "Product With Invalid Purchase"
    fill_in "SKU", with: "product-with-invalid-initial-purchase"

    franchise_select = find("select[name='product[franchise_id]']", visible: :all)
    page.execute_script("arguments[0].value = arguments[1]", franchise_select, franchise.id.to_s)

    shape_select = find("select[name='product[shape_id]']", visible: :all)
    page.execute_script("arguments[0].value = arguments[1]", shape_select, shape.id.to_s)

    click_button "Add Purchase"

    fill_in "Item price", with: "15"
    fill_in "Amount", with: "2"
    fill_in "What did you pay in total?", with: "30"

    expect {
      click_button "Create Product"
    }.not_to change(Product, :count)

    expect(page).to have_content("Fix errors and try again")
    expect(page).to have_content("Purchase Supplier")
    expect(page).to have_css("#purchase-supplier-field .field_with_errors")
    expect(find_field("purchase[item_price]").value).to eq("15")
    expect(find_field("purchase[amount]").value).to eq("2")
    expect(find_field("purchase[payment_value]").value).to eq("30")
  end

  scenario "re-renders with purchase field errors when the purchase is left blank", :js do # rubocop:disable RSpec/MultipleExpectations
    franchise = create(:franchise)
    shape = create(:shape)
    create(:warehouse, is_default: true)

    visit new_product_path

    fill_in "Title", with: "Product With Blank Purchase"
    fill_in "SKU", with: "product-with-blank-purchase"

    franchise_select = find("select[name='product[franchise_id]']", visible: :all)
    page.execute_script("arguments[0].value = arguments[1]", franchise_select, franchise.id.to_s)

    shape_select = find("select[name='product[shape_id]']", visible: :all)
    page.execute_script("arguments[0].value = arguments[1]", shape_select, shape.id.to_s)
    click_button "Add Purchase"

    expect {
      click_button "Create Product"
    }.not_to change(Product, :count)

    expect(page).to have_content("Fix errors and try again")
    expect(page).to have_content("Purchase Supplier")
    expect(page).to have_css("#purchase-supplier-field .field_with_errors")
    expect(page).to have_css("#purchase-item-price-field .field_with_errors")
    expect(page).to have_css("#purchase-amount-field .field_with_errors")
  end

  scenario "creates a product without a purchase when the purchase block stays closed" do # rubocop:disable RSpec/MultipleExpectations
    franchise = create(:franchise)
    shape = create(:shape)

    visit new_product_path

    expect(page).to have_button("Add Purchase")
    expect(page).not_to have_field("purchase[item_price]", visible: :all)

    fill_in "Title", with: "Product Without Purchase"
    fill_in "SKU", with: "product-without-purchase"

    select franchise.title, from: "product[franchise_id]"
    select shape.title, from: "product[shape_id]"

    expect {
      click_button "Create Product"
    }.to change(Product, :count).by(1)
      .and change(Purchase, :count).by(0)

    created_product = Product.find_by!(sku: "product-without-purchase")
    expect(page).to have_current_path(product_path(created_product))
    expect(page).to have_content("Product was successfully created")
  end
  # rubocop:enable RSpec/MultipleExpectations
end
