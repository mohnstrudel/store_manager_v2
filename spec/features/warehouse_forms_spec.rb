# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Warehouse forms", :js do
  before { sign_in_as_admin }
  after { log_out }

  scenario "creates a warehouse with a transition destination" do
    destination = create(:warehouse, name: "Main Stock")

    visit new_warehouse_path

    fill_in "Name", with: "Receiving"
    click_button "Add Transition"

    find("select[name='warehouse[to_warehouse_ids][]']").select(destination.name)

    click_button "Create Warehouse"

    created_warehouse = Warehouse.order(:id).last

    expect(page).to have_current_path(warehouse_path(created_warehouse))
    expect(page).to have_content("Warehouse was successfully created")
    expect(created_warehouse.from_transitions.where(to_warehouse: destination)).to exist
  end
end
