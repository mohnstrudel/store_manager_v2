# frozen_string_literal: true

require "rails_helper"

describe "GET /sales" do
  before { sign_in_as_admin }
  after { log_out }

  it "shows warehouse buttons instead of sale status on the index page" do
    sale = create(:sale, status: Sale.active_status_names.first)
    product = create(:product)
    sale_item = create(:sale_item, sale:, product:)
    warehouse = create(:warehouse, name: "Berlin Hub")
    purchase = create(:purchase, product:)
    purchase_item = create(:purchase_item, purchase:, warehouse:, sale_item:)

    visit sales_path

    expect(page).to have_css("a[href='#{purchase_item_path(purchase_item)}']", text: "Berlin Hub")
    expect(page).not_to have_text(sale.status.titleize)
  end
end
