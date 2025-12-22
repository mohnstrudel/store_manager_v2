# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Product Image Management" do
  before {
    sign_in_as_admin
    create_test_image("test1.jpg")
    create_test_image("test2.jpg")
    create_test_image("test3.jpg")
    create_test_image("replacement.jpg")
  }

  after {
    log_out
    cleanup_test_image("test1.jpg")
    cleanup_test_image("test2.jpg")
    cleanup_test_image("test3.jpg")
    cleanup_test_image("replacement.jpg")
  }

  let!(:product) { create(:product) }
  let(:first_image_path) { Rails.root.join("tmp/test1.jpg") }
  let(:second_image_path) { Rails.root.join("tmp/test2.jpg") }
  let(:third_image_path) { Rails.root.join("tmp/test3.jpg") }
  let(:replacement_image_path) { Rails.root.join("tmp/replacement.jpg") }

  scenario "adds three new images to a product", :js do # rubocop:todo RSpec/MultipleExpectations
    visit edit_product_path(product)

    # Find the new_images file input and attach 3 images
    attach_file("product[new_images][]", [first_image_path, second_image_path, third_image_path], visible: false)

    click_button "Update Product"

    expect(page).to have_content("Product was successfully updated")
    expect(product.reload.media.count).to eq(3)
  end

  scenario "changes positions of existing images", :js do # rubocop:todo RSpec/MultipleExpectations
    # Create 3 images with positions 0, 1, 2
    media1 = create(:media, :for_product, mediaable: product, position: 0)
    create(:media, :for_product, mediaable: product, position: 1)
    create(:media, :for_product, mediaable: product, position: 2)

    visit edit_product_path(product)

    # Change position of first image to 2
    within("fieldset", text: "Existing images") do
      first_input = all("input[name^='product[media_attributes]'][type='number']").first
      first_input.set(2)
    end

    click_button "Update Product"

    expect(page).to have_content("Product was successfully updated")

    # Reload and verify positions changed
    product.reload
    expect(product.media.find(media1.id).position).to eq(2)
  end

  scenario "removes an image", :js do # rubocop:todo RSpec/MultipleExpectations
    media1 = create(:media, :for_product, mediaable: product, position: 0)
    create(:media, :for_product, mediaable: product, position: 1)

    visit edit_product_path(product)

    # Click the Remove button on the first image
    within("fieldset", text: "Existing images") do
      first("button[data-form-image-target='removeButton']").click
    end

    click_button "Update Product"

    expect(page).to have_content("Product was successfully updated")
    expect(product.reload.media.count).to eq(1)
    expect(product.media.pluck(:id)).not_to include(media1.id)
  end

  scenario "replaces an image", :js do # rubocop:todo RSpec/MultipleExpectations
    media1 = create(:media, :for_product, mediaable: product, position: 0)

    visit edit_product_path(product)

    # Click Replace button and attach new file
    within("fieldset", text: "Existing images") do
      click_button "Replace"
      attach_file("product[media_attributes][0][image]", replacement_image_path, visible: false)
    end

    click_button "Update Product"

    expect(page).to have_content("Product was successfully updated")

    # Verify image was replaced (filename changes)
    media1.reload
    expect(media1.image.filename.to_s).to eq("replacement.jpg")
  end

  scenario "handles complex workflow: add, remove, replace, and reorder", :js do # rubocop:todo RSpec/MultipleExpectations
    # Start with 2 existing images
    media1 = create(:media, :for_product, mediaable: product, position: 0)
    create(:media, :for_product, mediaable: product, position: 1)

    visit edit_product_path(product)

    # Add new image
    attach_file("product[new_images][]", first_image_path, visible: false)

    # Remove first existing image
    within("fieldset", text: "Existing images") do
      first("button[data-form-image-target='removeButton']").click
    end

    # Replace second image
    within("fieldset", text: "Existing images") do
      all("button[data-form-image-target='replaceButton']").first.click
      attach_file("product[media_attributes][1][image]", replacement_image_path, visible: false)
    end

    # Change position of remaining image
    within("fieldset", text: "Existing images") do
      first("input[name^='product[media_attributes]'][type='number']").set(5)
    end

    click_button "Update Product"

    expect(page).to have_content("Product was successfully updated")

    # Verify final state
    product.reload
    expect(product.media.count).to eq(2) # 1 remaining + 1 new
    expect(product.media.pluck(:id)).not_to include(media1.id) # First removed
  end
end
