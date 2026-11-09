# frozen_string_literal: true

require "rails_helper"

describe "Moving purchased products between warehouses" do
  before { sign_in_as_admin }

  let(:warehouse_from) { create(:warehouse, name: "Warehouse From") }
  let!(:warehouse_to) { create(:warehouse, name: "Warehouse To") }
  let(:product) { create(:product) }
  let(:purchase) { create(:purchase, product: product) }
  let!(:purchase_items) do # rubocop:todo RSpec/LetSetup
    create_list(:purchase_item, 3, warehouse: warehouse_from, purchase: purchase)
  end

  context "when we visit purchases show page" do
    scenario "select purchased products and move to another warehouse", :js do # rubocop:todo RSpec/MultipleExpectations
      visit purchase_path(purchase)

      expect(page).to have_css("tr.hoverable", count: 3)
      expect(page).to have_text(warehouse_from.name, count: 3)

      find("tbody tr.hoverable:nth-of-type(1) input[type='checkbox']").check
      all("tbody tr.hoverable input[type='checkbox']")[1].check

      page.execute_script("document.querySelector('.move_to_warehouse__form').style.position = 'static';")

      choose_react_select(warehouse_to.name, from: "Destination warehouse")

      click_button "Move"

      expect(page).to have_content("Success! 2 purchased products moved to: #{warehouse_to.name}")

      expect(page).to have_css("tr.hoverable", count: 3)

      expect(page).to have_text(:visible, warehouse_to.name, count: 3)
    end
  end
end
