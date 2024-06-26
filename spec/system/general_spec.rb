require "rails_helper"

RSpec.describe "Search, create, and destroy", js: "true" do
  # rubocop:disable RSpec/MultipleExpectations, RSpec/InstanceVariable, RSpec/ExampleLength, RSpec/BeforeAfterAll
  describe "works accross products, sales, purchases, and debts" do
    before(:all) do
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
        :product_sale,
        sale: @sale_cooper,
        product: @asuka,
        variation: nil
      )
      @ps_cooper_2 = create(
        :product_sale,
        sale: @sale_cooper,
        product: @batman,
        variation: nil
      )
      @ps_cooper_3 = create(
        :product_sale,
        sale: @sale_cooper,
        product: @guts,
        variation: nil
      )
      @ps_palmer = create(
        :product_sale,
        sale: @sale_palmer,
        product: @batman,
        variation: nil
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
      Product.find_each(&:destroy)
      Customer.find_each(&:destroy)
      Sale.find_each(&:destroy)
      ProductSale.find_each(&:destroy)
      Purchase.find_each(&:destroy)
      Brand.find_each(&:destroy)
      Franchise.find_each(&:destroy)
      Shape.find_each(&:destroy)
      Supplier.find_each(&:destroy)
    end

    it "shows two sales and two suppliers debts in index" do
      visit root_path

      expect(page).to have_content(@batman.full_title)
      expect(page).to have_content(@guts.full_title)
      expect(page).to have_content(@supplier_fnc.title)
      expect(page).to have_content(@supplier_agk.title)
    end

    it "finds one product in Debts page" do
      visit debts_path

      expect(page).to have_content(@batman.full_title)
      expect(page).to have_content(@guts.full_title)

      fill_in "q", with: @batman.title
      find_by_id("q").native.send_keys(:return)

      expect(page).to have_content(@batman.full_title)
      expect(page).to have_no_content(@guts.full_title)
    end

    it "finds one customer in Sales page" do
      visit sales_path

      expect(page).to have_content(@laura_palmer.email)
      expect(page).to have_content(@dale_cooper.email)

      fill_in "q", with: @laura_palmer.email
      find_by_id("q").native.send_keys(:return)

      expect(page).to have_content(@laura_palmer.email)
      expect(page).to have_no_content(@dale_cooper.email)
    end

    it "finds one purchase in Purchases page" do
      visit purchases_path

      expect(page).to have_content(@asuka.full_title)
      expect(page).to have_content(@batman.full_title)

      fill_in "q", with: @asuka.full_title
      find_by_id("q").native.send_keys(:return)

      expect(page).to have_content(@asuka.full_title)
      expect(page).to have_no_content(@batman.full_title)
      expect(page).to have_no_content(@guts.full_title)
    end

    it "doesn't break debts when we change products" do
      4.times do
        create(
          :product_sale,
          sale: @sale_cooper,
          product: @batman,
          variation: nil
        )
      end
      dc_comics = create(:franchise, title: "DC Comics")

      visit debts_path

      fill_in "q", with: @batman.title
      find_by_id("q").native.send_keys(:return)

      expect(page).to have_content(@batman.full_title)
      expect(page).to have_content(6)

      find("tr[data-table-id-param='#{@batman.id}']").click
      find(:link, "Edit").click
      find("div[aria-expanded='false']", text: "Studio Ghibli").click

      find("div[aria-selected='false']", text: "DC Comics").click
      scroll_to("input[type=submit]")
      find("input[type=submit]").click

      visit debts_path

      fill_in "q", with: dc_comics.title
      find_by_id("q").native.send_keys(:return)

      expect(page).to have_content(Product.find(@batman.id).full_title)
      expect(page).to have_content(6)
    end

    it "doesn't break purchases when we change them" do
      asuka_variation = create(:variation, product: @asuka)

      visit purchases_path

      fill_in "q", with: @purchase_batman.order_reference
      find_by_id("q").native.send_keys(:return)

      find("tr[data-table-url-param='/purchases/#{@purchase_batman.friendly_id}']").click
      find(:link, "Edit").click

      find("#purchase-product-select div[role='combobox']").click
      find("div[aria-selected='false']", text: @asuka.full_title).click

      scroll_to("label[for='purchase_variation'] ~ div")

      find("#purchase-variation-select:last-child").click
      find("div[aria-selected='false']", text: asuka_variation.title).click

      scroll_to("input[type=submit]")
      find("input[type=submit]").click

      visit purchases_path

      fill_in "q", with: @purchase_batman.order_reference
      find_by_id("q").native.send_keys(:return)

      expect(page).to have_content(asuka_variation.title)
    end
  end

  describe "Debts respects purchases" do
    before do
      elder_ring = create(:franchise, title: "Elder Ring")

      regular = create(:version, value: "Regular Armor")
      revealing = create(:version, value: "Revealing Armor")

      @malenia = create(:product, title: "Malenia", franchise: elder_ring)

      create(
        :product_brand,
        product: @malenia,
        brand: create(:brand, title: "Coolbear Studio")
      )

      @malenia_regular = create(
        :variation,
        product: @malenia,
        version: regular
      )
      @malenia_revealing = create(
        :variation,
        product: @malenia,
        version: revealing
      )

      create_list(:product_sale, 3, product: @malenia, variation: nil)
      create_list(
        :product_sale,
        6,
        product: @malenia,
        variation: @malenia_regular
      )
      create_list(
        :product_sale,
        9,
        product: @malenia,
        variation: @malenia_revealing
      )
    end

    it "Shows the correct amount of purchases" do
      visit debts_path

      malenia_tr = "tr[data-table-id-param='#{@malenia.id}']"
      malenia_regular_tr = "tr[data-table-id-param='#{@malenia_regular.id}']"
      malenia_revealing_tr = "tr[data-table-id-param='#{@malenia_revealing.id}']"

      expect(page).to have_content(@malenia.full_title)
      expect(page).to have_content(@malenia_regular.title)
      expect(page).to have_content(@malenia_revealing.title)

      within malenia_tr do
        expect(find("td:nth-child(4)")).to have_text("0")
      end

      within malenia_regular_tr do
        expect(find("td:nth-child(4)")).to have_text("0")
      end

      within malenia_revealing_tr do
        expect(find("td:nth-child(4)")).to have_text("0")
      end

      create(:purchase, product: @malenia, amount: 1)

      refresh

      within malenia_tr do
        expect(find("td:nth-child(4)")).to have_text("1")
      end

      within malenia_regular_tr do
        expect(find("td:nth-child(4)")).to have_text("0")
      end

      within malenia_revealing_tr do
        expect(find("td:nth-child(4)")).to have_text("0")
      end

      create(:purchase, product: @malenia, variation: @malenia_regular, amount: 2)

      refresh

      within malenia_tr do
        expect(find("td:nth-child(4)")).to have_text("1")
      end

      within malenia_regular_tr do
        expect(find("td:nth-child(4)")).to have_text("2")
      end

      within malenia_revealing_tr do
        expect(find("td:nth-child(4)")).to have_text("0")
      end

      create(:purchase, product: @malenia, variation: @malenia_revealing, amount: 3)

      refresh

      within malenia_tr do
        expect(find("td:nth-child(4)")).to have_text("1")
      end

      within malenia_regular_tr do
        expect(find("td:nth-child(4)")).to have_text("2")
      end

      within malenia_revealing_tr do
        expect(find("td:nth-child(4)")).to have_text("3")
      end
    end
  end

  describe "Dashboard" do
    it "doesn't show the webhook error banner when the webhook is enabled" do
      allow(Config).to receive(:sales_hook_disabled?).and_return(false)
      visit dashboard_index_path

      expect(page).to have_no_selector("#webhook-error")
    end

    it "shows the webhook error banner when the webhook is disabled" do
      allow(Config).to receive(:sales_hook_disabled?).and_return(true)
      visit dashboard_index_path

      expect(page).to have_selector("#webhook-error")
      expect(page).to have_link("Get missing sales from Woo", href: "pull-last-orders")
    end
  end
  # rubocop:enable RSpec/MultipleExpectations, RSpec/InstanceVariable, RSpec/ExampleLength, RSpec/BeforeAfterAll
end
