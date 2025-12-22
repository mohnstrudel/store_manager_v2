# frozen_string_literal: true
require "rails_helper"

describe "Changing default warehouse" do
  before { sign_in_as_admin }
  after { log_out }

  let!(:existing_default_warehouse) { create(:warehouse, :default, name: "Default Warehouse") }
  let!(:non_default_warehouse) { create(:warehouse, name: "Non-Default Warehouse") }

  scenario "cannot change default warehouse when another default exists" do # rubocop:todo RSpec/MultipleExpectations
    visit edit_warehouse_path(non_default_warehouse)

    select "Yes", from: "Is default"
    click_button "Update Warehouse"

    expect(page).to have_content("change the current default warehouse \"Default Warehouse\" before setting a new one")
    expect(non_default_warehouse.reload.is_default).to be false
    expect(existing_default_warehouse.reload.is_default).to be true
  end

  scenario "can change default warehouse when no other default exists" do # rubocop:todo RSpec/MultipleExpectations
    existing_default_warehouse.update(is_default: false)

    visit edit_warehouse_path(non_default_warehouse)

    select "Yes", from: "Is default"
    click_button "Update Warehouse"

    expect(page).to have_content("Warehouse was successfully updated")
    expect(non_default_warehouse.reload.is_default).to be true
  end
end
