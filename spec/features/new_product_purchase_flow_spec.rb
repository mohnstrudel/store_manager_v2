# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating a product with a purchase" do
  before { sign_in_as_admin }

  scenario "creates both records for a Base-only Product", :js do # rubocop:todo RSpec/MultipleExpectations
    franchise = create(:franchise)
    brand = create(:brand, title: "Featured Brand")
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

    click_button "Add Purchase"

    choose_react_select(supplier.title, from: "Supplier")

    fill_in "Item price", with: "15"
    fill_in "Amount", with: "2"
    fill_in "What did you pay in total?", with: "30"

    choose_react_select(warehouse.name, from: "Initial warehouse")

    find("input[name='product[description]']", visible: false).set("<p>Product description</p>")

    click_button "Create Product"

    expect(page).to have_content("Product was successfully created")
    created_product = Product.find_by!(title: "Product With Purchase")
    purchase = created_product.purchases.last

    expect(page).to have_current_path(product_path(created_product))
    expect(created_product.brands).to include(brand)
    expect(created_product.description.body.to_html).to include("Product description")
    expect(purchase).to be_present
    expect(purchase.variant).to eq(created_product.base_variant)
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
      fill_in "List cost", with: "9.99"
      fill_in "Selling Price", with: "19.99"
    end

    click_button "Add Purchase"

    fill_in "Item price", with: "15"
    fill_in "Amount", with: "2"
    fill_in "What did you pay in total?", with: "30"

    click_button "Create Product"

    expect(page).to have_content("Fix errors and try again")
    expect(Product.count).to eq(0)
    expect(page).to have_content("Purchase Supplier")
    within ".purchase-fields" do
      expect(page).to have_content("Supplier")
      expect(page).to have_content("can't be blank")
    end
    expect(page).to have_css(".purchase-fields .field_with_errors .text_error.absolute", visible: :all)
    expect(find_field("purchase[item_price]").value).to eq("15")
    expect(find_field("purchase[amount]").value).to eq("2")
    expect(find_field("purchase[payment_value]").value).to eq("30")

    within(all(".variant-fields").last) do
      expect(find("input[name='variants[0][sku]']", visible: false).value).to eq(
        "product-with-invalid-initial-purchase-variant"
      )
      expect(find("input[name='variants[0][size_id]']", visible: false).value).to eq(size.id.to_s)
      expect(find("input[name='variants[0][version_id]']", visible: false).value).to eq(version.id.to_s)
      expect(find("input[name='variants[0][color_id]']", visible: false).value).to eq(color.id.to_s)
    end
  end
  # rubocop:enable RSpec/MultipleExpectations
end
