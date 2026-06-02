# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Purchase Item Image Management" do
  before {
    sign_in_as_admin
    create_test_image("item1.jpg")
  }

  after {
    log_out
    cleanup_test_image("item1.jpg")
  }

  let!(:purchase_item) { create(:purchase_item) }
  let(:image_path) { Rails.root.join("tmp/item1.jpg") }

  scenario "adds images to purchase item", :js do # rubocop:todo RSpec/MultipleExpectations
    visit edit_purchase_item_path(purchase_item)

    find('[data-testid="new-images-input"]', visible: false).set(image_path)
    expect(page).to have_css('[data-testid="image-pending-badge"]', count: 1, wait: 15)

    click_button "Update Purchase Item"

    expect(page).to have_content("Purchase item was successfully updated")
    expect(purchase_item.reload.media.count).to eq(1)
  end
end
