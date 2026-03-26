# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating a new purchase" do
  before { sign_in_as_admin }
  after { log_out }

  let!(:supplier) { create(:supplier) }
  let!(:product) { create(:product) }
  let!(:warehouse) { create(:warehouse, is_default: true) }

  scenario "creates purchased products in the default warehouse" do # rubocop:todo RSpec/MultipleExpectations
    visit new_purchase_path

    find("#purchase_supplier_id").set(supplier.id)
    find("#purchase_product_id", visible: false).set(product.id)
    find("#purchase_amount").set(5)
    find("#purchase_item_price").set(10)

    expect {
      click_button "Create Purchase"
    }.to change(Purchase, :count).by(1)
      .and change(PurchaseItem, :count).by(5)

    purchase = Purchase.last
    expect(purchase.purchase_items.count).to eq(5)
    expect(purchase.purchase_items.all? { |pp| pp.warehouse == warehouse }).to be true
  end

  scenario "creates an initial payment alongside the purchase" do # rubocop:todo RSpec/MultipleExpectations
    visit new_purchase_path

    find("#purchase_supplier_id").set(supplier.id)
    find("#purchase_product_id", visible: false).set(product.id)
    find("#purchase_amount").set(5)
    find("#purchase_item_price").set(10)
    fill_in "What did you pay in total?", with: "50"

    expect {
      click_button "Create Purchase"
    }.to change(Purchase, :count).by(1)
      .and change(Payment, :count).by(1)

    purchase = Purchase.last
    expect(purchase.payments.pluck(:value)).to eq([BigDecimal(50)])
  end

  # rubocop:todo RSpec/MultipleExpectations
  scenario "displays warehouse information on the purchase page after creation" do
    # rubocop:enable RSpec/MultipleExpectations
    visit product_path(product)

    expect(page).not_to have_selector("h3", text: "Purchases")

    visit new_purchase_path

    find("#purchase_supplier_id").set(supplier.id)
    find("#purchase_product_id", visible: false).set(product.id)
    find("#purchase_amount").set(5)
    find("#purchase_item_price").set(10)

    click_button "Create Purchase"

    purchase = Purchase.last
    expect(page).to have_current_path(purchase_path(purchase))

    expect(page).to have_text("Purchase Items: 5")

    visit product_path(product)

    expect(page).to have_selector("h3", text: "Purchases")
  end

  scenario "adds a payment after the purchase is created", :js do # rubocop:todo RSpec/MultipleExpectations
    visit new_purchase_path

    find("#purchase_supplier_id").set(supplier.id)
    find("#purchase_product_id", visible: false).set(product.id)
    find("#purchase_amount").set(2)
    find("#purchase_item_price").set(10)

    click_button "Create Purchase"

    expect(page).to have_content("Purchase was successfully created")

    fill_in "payment_amount", with: "20"
    click_button "Add payment"

    expect(page).to have_content("Payment was successfully created")
    expect(Purchase.last.payments.count).to eq(1)
    expect(Purchase.last.payments.first.value).to eq(BigDecimal(20))
  end
end
