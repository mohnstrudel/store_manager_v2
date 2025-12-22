# frozen_string_literal: true
require "rails_helper"

describe "Debts can take purchases into account" do
  before do
    sign_in_as_admin

    elder_ring = create(:franchise, title: "Elder Ring")

    regular = create(:version, value: "Regular Armor")
    revealing = create(:version, value: "Revealing Armor")

    @malenia = create(:product, title: "Malenia", franchise: elder_ring)

    create(
      :product_brand,
      product: @malenia, # rubocop:todo RSpec/InstanceVariable
      brand: create(:brand, title: "Coolbear Studio")
    )

    # Create a bunch of edition to prevent this test failing at production environment
    create_list(:edition, 3)

    @malenia_regular = create(
      :edition,
      product: @malenia, # rubocop:todo RSpec/InstanceVariable
      version: regular
    )
    @malenia_revealing = create(
      :edition,
      product: @malenia, # rubocop:todo RSpec/InstanceVariable
      version: revealing
    )

    create_list(:sale_item, 3, product: @malenia, edition: nil) # rubocop:todo RSpec/InstanceVariable
    create_list(
      :sale_item,
      6,
      product: @malenia, # rubocop:todo RSpec/InstanceVariable
      edition: @malenia_regular # rubocop:todo RSpec/InstanceVariable
    )
    create_list(
      :sale_item,
      9,
      product: @malenia, # rubocop:todo RSpec/InstanceVariable
      edition: @malenia_revealing # rubocop:todo RSpec/InstanceVariable
    )
  end

  after { log_out }

  it "shows the correct amount of purchases" do # rubocop:todo RSpec/MultipleExpectations
    visit debts_path

    malenia_selector = "tr[data-table-id-param='#{@malenia.id}']" # rubocop:todo RSpec/InstanceVariable
    malenia_regular_selector = "tr[data-table-id-param='#{@malenia_regular.id}']" # rubocop:todo RSpec/InstanceVariable
    # rubocop:todo RSpec/InstanceVariable
    malenia_revealing_selector = "tr[data-table-id-param='#{@malenia_revealing.id}']"
    # rubocop:enable RSpec/InstanceVariable

    purchases_selector = "td:nth-child(4)"

    expect(page).to have_text(@malenia.full_title) # rubocop:todo RSpec/InstanceVariable
    expect(page).to have_text(@malenia_regular.title) # rubocop:todo RSpec/InstanceVariable
    expect(page).to have_text(@malenia_revealing.title) # rubocop:todo RSpec/InstanceVariable

    within malenia_selector do
      expect(find(purchases_selector)).to have_text("0")
    end

    within malenia_regular_selector do
      expect(find(purchases_selector)).to have_text("0")
    end

    within malenia_revealing_selector do
      expect(find(purchases_selector)).to have_text("0")
    end

    create(:purchase, product: @malenia, amount: 1) # rubocop:todo RSpec/InstanceVariable

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

    create(:purchase, product: @malenia, edition: @malenia_regular, amount: 2) # rubocop:todo RSpec/InstanceVariable

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

    create(:purchase, product: @malenia, edition: @malenia_revealing, amount: 3) # rubocop:todo RSpec/InstanceVariable

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
