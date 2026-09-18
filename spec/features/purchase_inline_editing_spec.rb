# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Purchase inline editing" do
  before { sign_in_as_admin }
  after { log_out }

  scenario "keeps an invalid payment update open with its submitted date", :js do
    purchase = create(:purchase)
    payment = create(:payment, purchase:, payment_date: Date.new(2026, 5, 20))

    visit purchase_path(purchase)

    within("tr[data-payment-id='#{payment.id}']") do
      fill_in "payment_#{payment.id}_date", with: "2026-06-01"
      fill_in "payment_#{payment.id}_amount", with: ""
      click_button "Update"
    end

    expect(page).to have_text("can't be blank")
    expect(page).to have_field("payment_#{payment.id}_date", with: "2026-06-01")
    expect(page).to have_current_path(purchase_path(purchase))
  end

  scenario "keeps an invalid item expense form on the purchase page", :js do
    item = create(:purchase_item)

    visit purchase_path(item.purchase)

    item_expense_details = find("summary", text: "Item direct expenses").find(:xpath, "..")
    item_expense_details.find("summary").click

    within(item_expense_details) do
      find("input[aria-label='New expense amount']").set("4.25")
      click_button "Add expense"

      expect(page).to have_text("can't be blank")
      expect(page).to have_css("input[aria-label='New expense amount'][value='4.25']")
    end
    expect(page).to have_current_path(purchase_path(item.purchase))
  end
end
