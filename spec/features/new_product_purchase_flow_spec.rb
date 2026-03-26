# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating a product with an initial purchase" do
  before { sign_in_as_admin }
  after { log_out }

  scenario "creates both records from the new product form", :js do # rubocop:todo RSpec/MultipleExpectations
    franchise = create(:franchise)
    shape = create(:shape)
    supplier = create(:supplier)
    warehouse = create(:warehouse, is_default: true)

    visit new_product_path

    fill_in "Title", with: "Product With Initial Purchase"
    fill_in "SKU", with: "product-with-initial-purchase"

    franchise_select = find("select[name='product[franchise_id]']", visible: :all)
    page.execute_script("arguments[0].value = arguments[1]", franchise_select, franchise.id.to_s)

    shape_select = find("select[name='product[shape_id]']", visible: :all)
    page.execute_script("arguments[0].value = arguments[1]", shape_select, shape.id.to_s)

    supplier_select = find("select[name='initial_purchase[supplier_id]']", visible: :all)
    page.execute_script("arguments[0].value = arguments[1]", supplier_select, supplier.id.to_s)

    fill_in "Item price", with: "15"
    fill_in "Amount", with: "2"
    fill_in "What did you pay in total?", with: "30"

    warehouse_select = find("select[name='initial_purchase[warehouse_id]']", visible: :all)
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
end
