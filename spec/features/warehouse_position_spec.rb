require "rails_helper"

describe "Warehouse Position Management" do
  before do
    sign_in_as_admin
    # Create test warehouses with specific positions
    @warehouse1 = create(:warehouse, name: "Warehouse 1", external_name: "External 1", position: 1)
    @warehouse2 = create(:warehouse, name: "Warehouse 2", external_name: "External 2", position: 2)
    @warehouse3 = create(:warehouse, name: "Warehouse 3", external_name: "External 3", position: 3)
  end

  after { log_out }

  scenario "User changes warehouse position using dropdown", js: true do
    visit warehouses_path

    # Verify initial positions
    expect(page).to have_select("position", with_options: ["1", "2", "3"])

    # Find the select for Warehouse 2 and change its position
    within("tr", text: "Warehouse 2") do
      select "1", from: "position"
    end

    # Wait for page to reload after form submission
    expect(page).to have_content("We changed \"Warehouse 2\" position from 2 to 1")

    # Verify the warehouses have been reordered
    warehouse_names = page.all("tr td:nth-child(2) strong").map(&:text)
    expect(warehouse_names[0]).to eq("Warehouse 2")
    expect(warehouse_names[1]).to eq("Warehouse 1")
    expect(warehouse_names[2]).to eq("Warehouse 3")
  end
end
