# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating a product with a purchase" do
  before { sign_in_as_admin }
  after { log_out }

  scenario "shows validation errors when the new product form is submitted untouched", :aggregate_failures, :js do
    create(:franchise)

    visit new_product_path

    expect {
      click_button "Create Product"
    }.not_to change(Product, :count)

    expect(page).to have_current_path(new_product_path, ignore_query: true)
    expect(page).to have_content("Fix errors and try again")
    expect(page).to have_content("Title")
  end

  scenario "creates both records from the new product form", :js do # rubocop:todo RSpec/MultipleExpectations
    franchise = create(:franchise)
    brand = create(:brand, title: "Featured Brand")
    size = create(:size, value: "Large")
    version = create(:version, value: "Deluxe")
    color = create(:color, value: "Red")
    supplier = create(:supplier)
    warehouse = create(:warehouse, is_default: true)

    visit new_product_path

    fill_in "Title", with: "Product With Purchase"
    choose_react_select(franchise.title, from: "Franchise")
    select "Bust", from: "Shape"
    choose_react_select(brand.title, from: "Brand")

    expect(find("input[name='product[franchise_id]']", visible: false).value).to eq(franchise.id.to_s)
    expect(find("#product_shape").value).to eq("Bust")
    expect(all("input[name='product[brand_ids][]']", visible: false).map(&:value)).to include(brand.id.to_s)

    click_button "Add Variant"

    within(all(".variant-fields").last) do
      choose_react_select(size.value, from: "Size")
    end
    within(all(".variant-fields").last) do
      choose_react_select(version.value, from: "Version")
    end
    within(all(".variant-fields").last) do
      choose_react_select(color.value, from: "Color")
    end
    within(all(".variant-fields").last) do
      fill_in "SKU", with: "product-with-initial-purchase-variant"
      fill_in "Weight (kg)", with: "1.5"
      fill_in "Purchase Cost", with: "9.99"
      fill_in "Selling Price", with: "19.99"
    end

    click_button "Add Purchase"

    choose_react_select(supplier.title, from: "Supplier")

    fill_in "Item price", with: "15"
    fill_in "Amount", with: "2"
    fill_in "What did you pay in total?", with: "30"

    choose_react_select(warehouse.name, from: "Initial warehouse")

    find("input[name='product[description]']", visible: false).set("<p>Product description</p>")

    click_button "Create Product"

    expect(page).to have_content("Product was successfully created")

    created_product = Variant.find_by!(sku: "product-with-initial-purchase-variant").product
    purchase = created_product.purchases.last

    expect(page).to have_current_path(product_path(created_product))
    expect(created_product.brands).to include(brand)
    expect(created_product.description.body.to_html).to include("Product description")
    expect(purchase).to be_present
    expect(purchase.supplier).to eq(supplier)
    expect(purchase.purchase_items.count).to eq(2)
    expect(purchase.purchase_items.pluck(:warehouse_id).uniq).to eq([warehouse.id])
    expect(purchase.payments.pluck(:value)).to eq([BigDecimal(30)])
  end

  scenario "re-renders with purchase field errors when only part of it is filled in", :js do # rubocop:disable RSpec/MultipleExpectations
    franchise = create(:franchise)
    size = create(:size, value: "Large")
    version = create(:version, value: "Deluxe")
    color = create(:color, value: "Red")
    create(:warehouse, is_default: true)

    visit new_product_path

    fill_in "Title", with: "Product With Invalid Purchase"
    choose_react_select(franchise.title, from: "Franchise")
    expect(find("#product_shape").value).to eq(Product.default_shape)

    click_button "Add Variant"

    within(all(".variant-fields").last) do
      choose_react_select(size.value, from: "Size")
    end
    within(all(".variant-fields").last) do
      choose_react_select(version.value, from: "Version")
    end
    within(all(".variant-fields").last) do
      choose_react_select(color.value, from: "Color")
    end
    within(all(".variant-fields").last) do
      fill_in "SKU", with: "product-with-invalid-initial-purchase-variant"
      fill_in "Weight (kg)", with: "1.5"
      fill_in "Purchase Cost", with: "9.99"
      fill_in "Selling Price", with: "19.99"
    end

    click_button "Add Purchase"

    fill_in "Item price", with: "15"
    fill_in "Amount", with: "2"
    fill_in "What did you pay in total?", with: "30"

    expect {
      click_button "Create Product"
    }.not_to change(Product, :count)

    expect(page).to have_content("Fix errors and try again")
    expect(page).to have_content("Purchase Supplier")
    expect(find_field("purchase[item_price]").value).to eq("15")
    expect(find_field("purchase[amount]").value).to eq("2")
    expect(find_field("purchase[payment_value]").value).to eq("30")

    within(all(".variant-fields").last) do
      expect(find("input[name='variants[1][sku]']", visible: false).value).to eq(
        "product-with-invalid-initial-purchase-variant"
      )
      expect(find("input[name='variants[1][size_id]']", visible: false).value).to eq(size.id.to_s)
      expect(find("input[name='variants[1][version_id]']", visible: false).value).to eq(version.id.to_s)
      expect(find("input[name='variants[1][color_id]']", visible: false).value).to eq(color.id.to_s)
    end
  end

  scenario "re-renders with purchase field errors when the purchase is left blank", :js do # rubocop:disable RSpec/MultipleExpectations
    franchise = create(:franchise)
    create(:warehouse, is_default: true)

    visit new_product_path

    fill_in "Title", with: "Product With Blank Purchase"
    choose_react_select(franchise.title, from: "Franchise")
    expect(find("#product_shape").value).to eq(Product.default_shape)
    click_button "Add Purchase"

    expect {
      click_button "Create Product"
    }.not_to change(Product, :count)

    expect(page).to have_content("Fix errors and try again")
    expect(page).to have_css(".purchase-fields")
    within ".purchase-fields" do
      expect(page).to have_content("Supplier")
      expect(page).to have_content("can't be blank")
    end
  end

  scenario "creates a product without a purchase when the purchase block stays closed", :js do # rubocop:disable RSpec/MultipleExpectations
    franchise = create(:franchise)

    visit new_product_path

    expect(page).to have_button("Add Purchase")
    expect(page).not_to have_field("purchase[item_price]", visible: :all)

    fill_in "Title", with: "Product Without Purchase"
    choose_react_select(franchise.title, from: "Franchise")
    expect(find("#product_shape").value).to eq(Product.default_shape)

    expect { click_button "Create Product" }.to change(Product, :count).by(1)
    expect(Purchase.count).to eq(0)

    created_product = Product.order(:id).last
    expect(page).to have_current_path(product_path(created_product))
    expect(page).to have_content("Product was successfully created")
  end
  # rubocop:enable RSpec/MultipleExpectations
end
