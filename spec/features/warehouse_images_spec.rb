# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Warehouse Image Management" do
  before {
    sign_in_as_admin
    create_test_image("warehouse1.jpg")
    create_test_image("warehouse2.jpg")
  }

  after {
    log_out
    cleanup_test_image("warehouse1.jpg")
    cleanup_test_image("warehouse2.jpg")
  }

  let!(:warehouse) { create(:warehouse) }
  let(:first_image_path) { Rails.root.join("tmp/warehouse1.jpg") }
  let(:second_image_path) { Rails.root.join("tmp/warehouse2.jpg") }

  scenario "adds multiple warehouse images", :js do # rubocop:todo RSpec/MultipleExpectations
    visit edit_warehouse_path(warehouse)

    find('[data-testid="new-images-input"]', visible: false).set([first_image_path, second_image_path])
    expect(page).to have_css('[data-testid="image-pending-badge"]', count: 2, wait: 15)

    click_button "Update Warehouse"

    expect(page).to have_content("Warehouse was successfully updated")
    expect(warehouse.reload.media.count).to eq(2)
  end
end
