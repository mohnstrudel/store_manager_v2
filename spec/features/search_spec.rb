# frozen_string_literal: true

require "rails_helper"

describe "Search works across products, sales, purchases, and debts", js: true do
  before { sign_in_as_admin }
  after { log_out }

  let!(:warehouse) { create(:warehouse, is_default: true) }

  let!(:asuka) { create(:product, title: "Asuka") }
  let!(:batman) { create(:product, title: "Batman") }
  let!(:guts) { create(:product, title: "Guts") }

  let!(:supplier_fnc) { create(:supplier, title: "FNC") }
  let!(:supplier_agk) { create(:supplier, title: "AnitoysGK") }

  let!(:dale_cooper) do
    create(
      :customer,
      first_name: "Dale",
      last_name: "Cooper",
      email: "dale_cooper@fbi.gov"
    )
  end

  let!(:laura_palmer) do
    create(
      :customer,
      first_name: "Laura",
      last_name: "Palmer",
      email: "laura_palmer@black_lodge.io"
    )
  end

  let!(:sale_cooper) { create(:sale, customer: dale_cooper) }
  let!(:sale_palmer) { create(:sale, customer: laura_palmer) }

  let!(:purchase_asuka) do
    create(
      :purchase,
      product: asuka,
      amount: 1,
      supplier: supplier_fnc
    )
  end

  let!(:purchase_batman) do
    create(
      :purchase,
      product: batman,
      amount: 1,
      supplier: supplier_agk,
      order_reference: "123"
    )
  end

  before do
    create(:sale_item, sale: sale_cooper, product: asuka, variant: nil)
    create(:sale_item, sale: sale_cooper, product: batman, variant: nil)
    create(:sale_item, sale: sale_cooper, product: guts, variant: nil)
    create(:sale_item, sale: sale_palmer, product: batman, variant: nil)
  end

  it "shows the expected products and supplier debts on the index" do
    visit root_path

    aggregate_failures do
      expect(page).to have_text(batman.full_title)
      expect(page).to have_text(guts.full_title)
      expect(page).to have_text(supplier_fnc.title)
      expect(page).to have_text(supplier_agk.title)
    end
  end

  it "filters products on the debts page" do
    visit debts_path

    aggregate_failures do
      expect(page).to have_text(batman.full_title)
      expect(page).to have_text(guts.full_title)
    end

    fill_in "q", with: batman.title
    click_button "Search"

    aggregate_failures do
      expect(page).to have_text(batman.full_title)
      expect(page).to have_no_text(guts.full_title)
      expect(page.current_url).not_to include("button=")
    end
  end

  it "filters customers on the sales page" do
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

  it "filters purchases on the purchases page" do
    visit purchases_path

    aggregate_failures do
      expect(page).to have_text(asuka.full_title)
      expect(page).to have_text(batman.full_title)
    end

    fill_in "q", with: asuka.full_title
    click_button "Search"

    aggregate_failures do
      expect(page).to have_text(asuka.full_title)
      expect(page).to have_no_text(batman.full_title)
      expect(page).to have_no_text(guts.full_title)
      expect(page.current_url).not_to include("button=")
    end
  end

  it "updates the debts page when product associations change" do
    4.times do
      create(:sale_item, sale: sale_cooper, product: batman, variant: nil)
    end

    dc_comics = create(:franchise, title: "DC Comics")

    visit debts_path

    fill_in "q", with: batman.title
    click_button "Search"

    batman_selector = "tr[data-table-id-param='#{batman.id}']"
    sold_amount_selector = "td:nth-child(3)"
    sold_amount = 6

    within batman_selector do
      expect(page).to have_text(batman.full_title)
      expect(find(sold_amount_selector)).to have_text(sold_amount)
    end

    # Open the row, then edit the product assignment
    find(batman_selector).click
    find(:link, "Edit").click
    # Click on the franchise dropdown select
    find("div[aria-expanded='false']", text: "Studio Ghibli").click
    # Select the new franchise
    find("div[aria-selected='false']", text: dc_comics.title).click
    scroll_to("input[type=submit]")
    find("input[type=submit]").click

    visit debts_path

    fill_in "q", with: dc_comics.title
    click_button "Search"

    within batman_selector do
      expect(page).to have_text(Product.find(batman.id).full_title)
      expect(find(sold_amount_selector)).to have_text(sold_amount)
    end
  end

  it "updates the purchases page when a purchase changes product" do
    asuka_variant = create(:variant, product: asuka)

    visit purchases_path

    fill_in "q", with: purchase_batman.order_reference
    click_button "Search"

    # Open the purchase row, then edit the product relation
    find("tr[data-table-url-param='/purchases/#{purchase_batman.friendly_id}']").click
    find("a[href='/purchases/#{purchase_batman.friendly_id}/edit']", text: "Edit").click

    # Click on the products dropdown select
    # and select a different product
    slim_select(batman.build_full_title_with_shop_id, asuka.build_full_title_with_shop_id)

    scroll_to("label[for='purchase_variant'] ~ div")
    # Select a variant for the new product
    find("#purchase-variant-select:last-child").click
    find("div[aria-selected='false']", text: asuka_variant.title).click

    scroll_to("input[type=submit]")
    find("input[type=submit]").click

    visit purchases_path

    fill_in "q", with: purchase_batman.order_reference
    click_button "Search"

    expect(page).to have_text(asuka_variant.title)
  end
end
