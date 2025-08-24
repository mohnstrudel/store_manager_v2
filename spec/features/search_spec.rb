require "rails_helper"

describe "Search works accross products, sales, purchases, and debts", js: "true" do
  before { sign_in_as_admin }
  after { log_out }

  # rubocop:disable RSpec/MultipleExpectations, RSpec/InstanceVariable, RSpec/ExampleLength, RSpec/BeforeAfterAll
  before(:all) do
    create(:warehouse, is_default: true)
    @asuka = create(:product, title: "Asuka")
    @batman = create(:product, title: "Batman")
    @guts = create(:product, title: "Guts")

    @supplier_fnc = create(:supplier, title: "FNC")
    @supplier_agk = create(:supplier, title: "AnitoysGK")

    @dale_cooper = create(
      :customer,
      first_name: "Dale",
      last_name: "Cooper",
      email: "dale_cooper@fbi.gov"
    )
    @laura_palmer = create(
      :customer,
      first_name: "Laura",
      last_name: "Palmer",
      email: "laura_palmer@black_lodge.io"
    )

    @sale_cooper = create(:sale, customer: @dale_cooper)
    @sale_palmer = create(:sale, customer: @laura_palmer)

    @ps_cooper_1 = create(
      :sale_item,
      sale: @sale_cooper,
      product: @asuka,
      edition: nil
    )
    @ps_cooper_2 = create(
      :sale_item,
      sale: @sale_cooper,
      product: @batman,
      edition: nil
    )
    @ps_cooper_3 = create(
      :sale_item,
      sale: @sale_cooper,
      product: @guts,
      edition: nil
    )
    @ps_palmer = create(
      :sale_item,
      sale: @sale_palmer,
      product: @batman,
      edition: nil
    )

    @purchase_asuka = create(
      :purchase,
      product: @asuka,
      amount: 1,
      supplier: @supplier_fnc
    )
    @purchase_batman = create(
      :purchase,
      product: @batman,
      amount: 1,
      supplier: @supplier_agk,
      order_reference: "123"
    )
  end

  after(:all) do
    Warehouse.find_each(&:destroy)
    Product.find_each(&:destroy)
    Customer.find_each(&:destroy)
    Sale.find_each(&:destroy)
    SaleItem.find_each(&:destroy)
    Purchase.find_each(&:destroy)
    Brand.find_each(&:destroy)
    Franchise.find_each(&:destroy)
    Shape.find_each(&:destroy)
    Supplier.find_each(&:destroy)
  end

  it "shows two sales and two suppliers debts in index" do
    visit root_path

    expect(page).to have_text(@batman.full_title)
    expect(page).to have_text(@guts.full_title)
    expect(page).to have_text(@supplier_fnc.title)
    expect(page).to have_text(@supplier_agk.title)
  end

  it "finds the queried product in Debts page" do
    visit debts_path

    expect(page).to have_text(@batman.full_title)
    expect(page).to have_text(@guts.full_title)

    fill_in "q", with: @batman.title
    find_by_id("q").native.send_keys(:return)

    expect(page).to have_text(@batman.full_title)
    expect(page).to have_no_text(@guts.full_title)
  end

  it "finds the queried customer in Sales page" do
    visit sales_path

    expect(page).to have_text(@laura_palmer.email)
    expect(page).to have_text(@dale_cooper.email)

    fill_in "q", with: @laura_palmer.email
    find_by_id("q").native.send_keys(:return)

    expect(page).to have_text(@laura_palmer.email)
    expect(page).to have_no_text(@dale_cooper.email)
  end

  it "finds the queried purchase in Purchases page" do
    visit purchases_path

    expect(page).to have_text(@asuka.full_title)
    expect(page).to have_text(@batman.full_title)

    fill_in "q", with: @asuka.full_title
    find_by_id("q").native.send_keys(:return)

    expect(page).to have_text(@asuka.full_title)
    expect(page).to have_no_text(@batman.full_title)
    expect(page).to have_no_text(@guts.full_title)
  end

  it "finds debts when we change products" do
    4.times do
      create(
        :sale_item,
        sale: @sale_cooper,
        product: @batman,
        edition: nil
      )
    end

    dc_comics = create(:franchise, title: "DC Comics")

    visit debts_path

    fill_in "q", with: @batman.title
    find_by_id("q").native.send_keys(:return)

    batman_selector = "tr[data-table-id-param='#{@batman.id}']"
    sold_amount_selector = "td:nth-child(3)"
    sold_amount = 6

    within batman_selector do
      expect(page).to have_text(@batman.full_title)
      expect(find(sold_amount_selector)).to have_text(sold_amount)
    end

    find(batman_selector).click
    find(:link, "Edit").click
    find("div[aria-expanded='false']", text: "Studio Ghibli").click

    find("div[aria-selected='false']", text: "DC Comics").click
    scroll_to("input[type=submit]")
    find("input[type=submit]").click

    visit debts_path

    fill_in "q", with: dc_comics.title
    find_by_id("q").native.send_keys(:return)

    within batman_selector do
      expect(page).to have_text(Product.find(@batman.id).full_title)
      expect(find(sold_amount_selector)).to have_text(sold_amount)
    end
  end

  it "finds purchases when we change them" do
    # Create a edition of the product that we will use later
    asuka_edition = create(:edition, product: @asuka)

    # Go to all purchases
    visit purchases_path

    # Find @purchase_batman
    fill_in "q", with: @purchase_batman.order_reference
    find_by_id("q").native.send_keys(:return)

    # Go to the purchase page we were searching for
    find("tr[data-table-url-param='/purchases/#{@purchase_batman.friendly_id}']").click

    # "Edit" the current purchase
    find("a[href='/purchases/#{@purchase_batman.friendly_id}/edit']", text: "Edit").click

    # Click on the products dropdown select
    # and select a different product
    slim_select(@batman.build_full_title_with_shop_id, @asuka.build_full_title_with_shop_id)

    scroll_to("label[for='purchase_edition'] ~ div")

    # Select a edition of the new product
    find("#purchase-edition-select:last-child").click
    find("div[aria-selected='false']", text: asuka_edition.title).click

    # Save changes
    scroll_to("input[type=submit]")
    find("input[type=submit]").click

    # Go back to all purchases
    visit purchases_path

    # Search for our edited purchase by the reference
    fill_in "q", with: @purchase_batman.order_reference
    find_by_id("q").native.send_keys(:return)

    # Expect to find the edited purchase
    expect(page).to have_text(asuka_edition.title)
  end
  # rubocop:enable RSpec/MultipleExpectations, RSpec/InstanceVariable, RSpec/ExampleLength, RSpec/BeforeAfterAll
end
