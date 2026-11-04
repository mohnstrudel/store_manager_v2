# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Product Image Management" do
  before {
    sign_in_as_admin
    create_test_image("test1.jpg")
  }

  after {
    cleanup_test_image("test1.jpg")
  }

  let!(:product) { create(:product) }
  let(:first_image_path) { Rails.root.join("tmp/test1.jpg") }

  def attach_new_images(*paths)
    find("[data-testid='new-images-input']", visible: false).set(paths.map(&:to_s))
    expect(page).to have_css("[data-testid='image-pending-badge']", count: paths.size, wait: 15)
  end

  scenario "adds a new image and removes an existing one in the same save", :js do # rubocop:todo RSpec/MultipleExpectations
    media1 = create(:media, :for_product, mediaable: product, position: 0)
    create(:media, :for_product, mediaable: product, position: 1)

    visit edit_product_path(product)

    attach_new_images(first_image_path)

    find("[data-testid='image-remove-btn']", match: :first).click

    click_button "Update Product"

    expect(page).to have_content("Product was successfully updated")

    product.reload
    expect(product.media.count).to eq(2)
    expect(product.media.pluck(:id)).not_to include(media1.id)
  end
end
