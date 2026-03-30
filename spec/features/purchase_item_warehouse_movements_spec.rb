# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Purchase item warehouse movements" do
  before { sign_in_as_admin }
  after { log_out }

  scenario "shows warehouse movement history on the purchase item page" do
    first_warehouse = create(:warehouse, name: "Warehouse One")
    second_warehouse = create(:warehouse, name: "Warehouse Two")
    purchase_item = create(:purchase_item, warehouse: first_warehouse)

    purchase_item.move_to_warehouse!(second_warehouse.id)

    visit purchase_item_path(purchase_item)

    within("table.vertical") do
      expect(page).to have_content("Moved in")
      expect(page).to have_content("Warehouse")
      expect(page).to have_content("Warehouse One")
      expect(page).to have_content("Warehouse Two")
      expect(page).to have_content(purchase_item.audits.first.created_at.strftime("%-d. %b ’%y %H:%M"))
      expect(page).to have_content(purchase_item.audits.second.created_at.strftime("%-d. %b ’%y %H:%M"))
    end
  end
end
