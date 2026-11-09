# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating a new purchase" do
  before { sign_in_as_admin }

  let!(:supplier) { create(:supplier) }
  let!(:product) { create(:product) }
  let!(:warehouse) { create(:warehouse, is_default: true) }

  # rubocop:todo RSpec/MultipleExpectations
  scenario "rejects an empty purchase, then creates purchased products in the default warehouse with an initial payment and adds a payment", :js do
    # rubocop:enable RSpec/MultipleExpectations
    visit new_purchase_path

    click_button "Create Purchase"

    expect(page).to have_content("Fix errors and try again")
    expect(page).to have_css("#purchase_product_id_error", text: "can't be blank")
    expect(Purchase.count).to eq(0)

    choose_react_select(supplier.title, from: "Supplier")
    choose_react_select(product.build_full_title_with_shop_id, from: "Product")
    expect(find("input[name='purchase[product_id]']", visible: false).value).to eq(product.id.to_s)
    find("#purchase_amount").set(5)
    find("#purchase_item_price").set(10)
    fill_in "What did you pay in total?", with: "50"

    expect {
      click_button "Create Purchase"
      expect(page).to have_content("Purchase was successfully created")
    }.to change(Purchase, :count).by(1)
      .and change(PurchaseItem, :count).by(5)
      .and change(Payment, :count).by(1)

    purchase = Purchase.last
    expect(page).to have_current_path(purchase_path(purchase))
    expect(purchase.purchase_items.count).to eq(5)
    expect(purchase.purchase_items.all? { |pp| pp.warehouse == warehouse }).to be true
    expect(purchase.payments.pluck(:value)).to eq([BigDecimal(50)])

    within(first(".table_card")) do
      expect(page).to have_link(product.full_title, href: product_path(product))
    end

    expect(find("#payment_date").value).to eq(Date.current.iso8601)
    fill_in "payment_amount", with: "20"
    find("#payment_date").set("2026-03-29")
    click_button "Add payment"

    expect(page).to have_content("Payment was successfully created")
    added_payment = purchase.payments.order(:id).last
    expect(purchase.payments.count).to eq(2)
    expect(added_payment.value).to eq(BigDecimal(20))
    expect(added_payment.payment_date.to_date).to eq(Date.new(2026, 3, 29))
  end
end
