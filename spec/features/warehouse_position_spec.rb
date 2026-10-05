# frozen_string_literal: true

require "rails_helper"

describe "Warehouse Position Management" do
  before do
    sign_in_as_admin
    @warehouse1 = create(:warehouse, name: "Warehouse 1", external_name_en: "External 1", position: 1)
    @warehouse2 = create(:warehouse, name: "Warehouse 2", external_name_en: "External 2", position: 2)
    @warehouse3 = create(:warehouse, name: "Warehouse 3", external_name_en: "External 3", position: 3)
  end

  after { log_out }

  scenario "User changes warehouse position using dropdown", :js do # rubocop:todo RSpec/MultipleExpectations
    visit warehouses_path

    expect(page).to have_select("position", with_options: ["1", "2", "3"])

    within("tr", text: "Warehouse 2") do
      select "1", from: "position"
    end

    expect(page).to have_content("We changed \"Warehouse 2\" position from 2 to 1")

    warehouse_names = page.all("tr td:nth-child(2) strong").map(&:text)
    expect(warehouse_names[0]).to eq("Warehouse 2")
    expect(warehouse_names[1]).to eq("Warehouse 1")
    expect(warehouse_names[2]).to eq("Warehouse 3")
  end
end
