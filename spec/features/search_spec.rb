# frozen_string_literal: true

require "rails_helper"

describe "Search works across sales and purchase edits", :js do
  before { sign_in_as_admin }

  it "filters customers on the sales page" do
    dale_cooper = create(:customer, first_name: "Dale", last_name: "Cooper", email: "dale_cooper@fbi.gov")
    laura_palmer = create(:customer, first_name: "Laura", last_name: "Palmer", email: "laura_palmer@black_lodge.io")
    create(:sale, customer: dale_cooper)
    create(:sale, customer: laura_palmer)

    visit sales_path

    aggregate_failures do
      expect(page).to have_text(laura_palmer.email)
      expect(page).to have_text(dale_cooper.email)
    end

    fill_in "q", with: laura_palmer.email
    click_button "Search"

    aggregate_failures do
      expect(page).to have_text(laura_palmer.email)
      expect(page).to have_no_text(dale_cooper.email)
      expect(page.current_url).not_to include("button=")
    end
  end

  it "saves a purchase moved to another product and variant" do
    asuka = create(:product, title: "Asuka")
    asuka_variant = create(:variant, product: asuka)
    purchase = create(:purchase, product: create(:product, title: "Batman"), order_reference: "123")

    visit edit_purchase_path(purchase)

    choose_react_select(asuka.build_full_title_with_shop_id, from: "Product")
    choose_react_select(asuka_variant.title, from: "Variant")

    scroll_to("button[type=submit]")
    find("button[type=submit]").click

    expect(page).to have_content("Purchase was successfully updated")
    expect(purchase.reload).to have_attributes(product: asuka, variant: asuka_variant)
  end
end
