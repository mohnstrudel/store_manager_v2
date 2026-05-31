# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Warehouse forms", :js do
  before { sign_in_as_admin }
  after { log_out }

  scenario "adds and removes transition rows on the edit page" do
    warehouse = create(:warehouse, name: "Receiving")

    visit edit_warehouse_path(warehouse)

    expect(page).not_to have_css("select[name='warehouse[to_warehouse_ids][]']")

    click_button "Add Transition"

    expect(page).to have_css("select[name='warehouse[to_warehouse_ids][]']", count: 1)

    click_button "Remove"

    expect(page).not_to have_css("select[name='warehouse[to_warehouse_ids][]']")
  end

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

  scenario "saves the edit form without changes" do
    warehouse = create(:warehouse, name: "Receiving", cbm: "12")

    visit edit_warehouse_path(warehouse)

    click_button "Update Warehouse"

    expect(page).to have_current_path(warehouse_path(warehouse))
    expect(page).to have_content("Warehouse was successfully updated")
    expect(warehouse.reload.cbm).to eq("12")
  end

  scenario "keeps transition rows after an invalid submit", :js do
    destination = create(:warehouse, name: "Main Stock")

    visit new_warehouse_path

    click_button "Add Transition"
    find("select[name='warehouse[to_warehouse_ids][]']").select(destination.name)

    click_button "Create Warehouse"

    expect(page).to have_content("Fix errors and try again")
    expect(page).to have_css("select[name='warehouse[to_warehouse_ids][]']", count: 1)
    expect(find("select[name='warehouse[to_warehouse_ids][]']").value).to eq(destination.id.to_s)
  end
end
