# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sale items form" do
  before { sign_in_as_admin }
  after { log_out }

  scenario "removes an existing sale item from a sale", :js do # rubocop:todo RSpec/MultipleExpectations
    sale = create(:sale)
    product = create(:product, title: "Removable Product")
    create(:sale_item, sale:, product:, edition: nil, qty: 2, price: 100)

    visit edit_sale_path(sale)

    within ".sales-form__product_fields", text: "Removable Product" do
      click_button "Remove"
    end

    click_button "Update Sale"

    expect(page).to have_content("Sale was successfully updated")
    expect(sale.reload.sale_items).to be_empty
  end
end
