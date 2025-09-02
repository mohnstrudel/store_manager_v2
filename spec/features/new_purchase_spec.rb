require "rails_helper"

RSpec.describe "Creating a new purchase", type: :feature do
  before { sign_in_as_admin }
  after { log_out }

  let!(:supplier) { create(:supplier) }
  let!(:product) { create(:product) }
  let!(:warehouse) { create(:warehouse, is_default: true) }

  scenario "creates purchased products in the default warehouse" do
    visit new_purchase_path

    find("#purchase_supplier_id").set(supplier.id)
    find("#purchase_product_id", visible: false).set(product.id)
    find("#purchase_amount").set(5)
    find("#purchase_item_price").set(10)
    find("#purchase_payments_attributes_0_value").set(10)

    expect {
      click_button "Create Purchase"
    }.to change(Purchase, :count).by(1)
      .and change(PurchaseItem, :count).by(5)

    purchase = Purchase.last
    expect(purchase.purchase_items.count).to eq(5)
    expect(purchase.purchase_items.all? { |pp| pp.warehouse == warehouse }).to be true
  end

  scenario "displays warehouse information on the purchase page after creation" do
    visit product_path(product)

    expect(page).not_to have_selector("h3", text: "Purchases")

    visit new_purchase_path

    find("#purchase_supplier_id").set(supplier.id)
    find("#purchase_product_id", visible: false).set(product.id)
    find("#purchase_amount").set(5)
    find("#purchase_item_price").set(10)
    find("#purchase_payments_attributes_0_value").set(10)

    click_button "Create Purchase"

    purchase = Purchase.last
    expect(page).to have_current_path(purchase_path(purchase))

    expect(page).to have_text("Purchase Items: 5")

    visit product_path(product)

    expect(page).to have_selector("h3", text: "Purchases")
  end
end
