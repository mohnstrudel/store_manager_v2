# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Product Image Management" do
  before {
    sign_in_as_admin
    create_test_image("test1.jpg")
    create_test_image("test2.jpg")
    create_test_image("test3.jpg")
  }

  after {
    log_out
    cleanup_test_image("test1.jpg")
    cleanup_test_image("test2.jpg")
    cleanup_test_image("test3.jpg")
  }

  let!(:product) { create(:product) }
  let(:first_image_path) { Rails.root.join("tmp/test1.jpg") }
  let(:second_image_path) { Rails.root.join("tmp/test2.jpg") }
  let(:third_image_path) { Rails.root.join("tmp/test3.jpg") }

  def attach_new_images(*paths)
    find("[data-testid='new-images-input']", visible: false).set(paths.map(&:to_s))
    # Wait for all uploads to finish — each successful upload renders a pending badge
    expect(page).to have_css("[data-testid='image-pending-badge']", count: paths.size, wait: 15)
  end

  scenario "adds three new images to a product", :js do # rubocop:todo RSpec/MultipleExpectations
    visit edit_product_path(product)

    attach_new_images(first_image_path, second_image_path, third_image_path)

    click_button "Update Product"

    expect(page).to have_content("Product was successfully updated")
    expect(product.reload.media.count).to eq(3)
  end

  scenario "adds a single new image to a product", :js do # rubocop:todo RSpec/MultipleExpectations
    visit edit_product_path(product)

    attach_new_images(first_image_path)

    click_button "Update Product"

    expect(page).to have_content("Product was successfully updated")
    expect(product.reload.media.count).to eq(1)
  end

  scenario "removes an image", :js do # rubocop:todo RSpec/MultipleExpectations
    media1 = create(:media, :for_product, mediaable: product, position: 0)
    create(:media, :for_product, mediaable: product, position: 1)

    visit edit_product_path(product)

    all("[data-testid='image-remove-btn']").first.click

    click_button "Update Product"

    expect(page).to have_content("Product was successfully updated")
    expect(product.reload.media.count).to eq(1)
    expect(product.media.pluck(:id)).not_to include(media1.id)
  end

  scenario "adds a new image and removes an existing one in the same save", :js do # rubocop:todo RSpec/MultipleExpectations
    media1 = create(:media, :for_product, mediaable: product, position: 0)
    create(:media, :for_product, mediaable: product, position: 1)

    visit edit_product_path(product)

    attach_new_images(first_image_path)

    all("[data-testid='image-remove-btn']").first.click

    click_button "Update Product"

    expect(page).to have_content("Product was successfully updated")

    product.reload
    expect(product.media.count).to eq(2) # 1 remaining + 1 new
    expect(product.media.pluck(:id)).not_to include(media1.id)
  end

end
