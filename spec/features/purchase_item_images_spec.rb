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

    attach_file("purchase_item[new_images][]", image_path, visible: false)

    click_button "Update Purchase item"

    expect(page).to have_content("Purchase item was successfully updated")
    expect(purchase_item.reload.media.count).to eq(1)
  end
end
