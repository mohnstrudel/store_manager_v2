# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Purchase inline editing" do
  before { sign_in_as_admin }

  # rubocop:todo RSpec/MultipleExpectations
  scenario "keeps invalid payment and item expense edits open on the purchase page, then saves the fixed payment", :js do
    # rubocop:enable RSpec/MultipleExpectations
    purchase = create(:purchase)
    payment = create(:payment, purchase:, value: 10, payment_date: Date.new(2026, 5, 20))
    create(:purchase_item, purchase:)

    visit purchase_path(purchase)

    within("tr[data-payment-id='#{payment.id}']") do
      fill_in "payment_#{payment.id}_date", with: "2026-06-01"
      fill_in "payment_#{payment.id}_amount", with: ""
      click_button "Update"
    end

    expect(page).to have_text("can't be blank")
    expect(page).to have_field("payment_#{payment.id}_date", with: "2026-06-01")
    expect(page).to have_current_path(purchase_path(purchase))

    within("tr[data-payment-id='#{payment.id}']") do
      fill_in "payment_#{payment.id}_amount", with: "25"
      click_button "Update"
    end

    expect(page).to have_content("Payment was successfully updated")
    expect(payment.reload.value).to eq(BigDecimal(25))
    expect(payment.payment_date.to_date).to eq(Date.new(2026, 6, 1))

    item_expense_details = find("summary", text: "Item direct expenses").find(:xpath, "..")
    item_expense_details.find("summary").click

    within(item_expense_details) do
      find("input[aria-label='New expense amount']").set("4.25")
      click_button "Add expense"

      expect(page).to have_text("can't be blank")
      expect(page).to have_css("input[aria-label='New expense amount'][value='4.25']")
    end
    expect(page).to have_current_path(purchase_path(purchase))
  end
end
