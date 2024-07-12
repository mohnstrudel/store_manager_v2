require "rails_helper"

describe "Debts can take purchases into account" do
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

    # Create a bunch of variation to prevent this test failing at production environment
    create_list(:variation, 3)

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

  it "shows the correct amount of purchases" do
    visit debts_path

    malenia_selector = "tr[data-table-id-param='#{@malenia.id}']"
    malenia_regular_selector = "tr[data-table-id-param='#{@malenia_regular.id}']"
    malenia_revealing_selector = "tr[data-table-id-param='#{@malenia_revealing.id}']"

    purchases_selector = "td:nth-child(4)"

    expect(page).to have_text(@malenia.full_title)
    expect(page).to have_text(@malenia_regular.title)
    expect(page).to have_text(@malenia_revealing.title)

    within malenia_selector do
      expect(find(purchases_selector)).to have_text("0")
    end

    within malenia_regular_selector do
      expect(find(purchases_selector)).to have_text("0")
    end

    within malenia_revealing_selector do
      expect(find(purchases_selector)).to have_text("0")
    end

    create(:purchase, product: @malenia, amount: 1)

    refresh

    within malenia_selector do
      expect(find(purchases_selector)).to have_text("1")
    end

    within malenia_regular_selector do
      expect(find(purchases_selector)).to have_text("0")
    end

    within malenia_revealing_selector do
      expect(find(purchases_selector)).to have_text("0")
    end

    create(:purchase, product: @malenia, variation: @malenia_regular, amount: 2)

    refresh

    within malenia_selector do
      expect(find(purchases_selector)).to have_text("1")
    end

    within malenia_regular_selector do
      expect(find(purchases_selector)).to have_text("2")
    end

    within malenia_revealing_selector do
      expect(find(purchases_selector)).to have_text("0")
    end

    create(:purchase, product: @malenia, variation: @malenia_revealing, amount: 3)

    refresh

    within malenia_selector do
      expect(find(purchases_selector)).to have_text("1")
    end

    within malenia_regular_selector do
      expect(find(purchases_selector)).to have_text("2")
    end

    within malenia_revealing_selector do
      expect(find(purchases_selector)).to have_text("3")
    end
  end
end
