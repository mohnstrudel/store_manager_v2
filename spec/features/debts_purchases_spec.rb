require "rails_helper"

describe "Purchases are taken into account when calculating debts" do
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

  it "Debts page shows the correct amount of purchases" do
    visit debts_path

    malenia_tr = "tr[data-table-id-param='#{@malenia.id}']"
    malenia_regular_tr = "tr[data-table-id-param='#{@malenia_regular.id}']"
    malenia_revealing_tr = "tr[data-table-id-param='#{@malenia_revealing.id}']"

    expect(page).to have_text(@malenia.full_title)
    expect(page).to have_text(@malenia_regular.title)
    expect(page).to have_text(@malenia_revealing.title)

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
