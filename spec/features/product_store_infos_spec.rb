# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Product Store Info Management" do
  before { sign_in_as_admin }

  let!(:product) { create(:product) }

  # Product with only shopify_info (missing woo_info) to test adding new store_infos
  let!(:product_with_one_store) do
    p = create(:product)
    p.woo_info.destroy
    p
  end

  scenario "edits existing store_info tags on product edit page", :js do # rubocop:todo RSpec/MultipleExpectations
    visit edit_product_path(product)

    # Verify page loads and shows store information section
    expect(page).to have_content("Store Information")
    expect(page).to have_content("Manage store information for this product")

    # Verify existing store_infos are displayed
    expect(page).to have_content("Shopify")
    expect(page).to have_content("Woo")

    # Find and update Shopify tags
    shopify_section = find(".store-info-fields", text: "Shopify")
    shopify_tags_field = shopify_section.find_field("Tags")

    # Verify current tags are visible (empty initially)
    expect(shopify_tags_field.value).to eq("")

    # Fill in new tags
    shopify_tags_field.fill_in with: "featured, new-arrival, sale"

    # Find and update Woo tags
    woo_section = find(".store-info-fields", text: "Woo")
    woo_tags_field = woo_section.find_field("Tags")

    # Fill in new tags
    woo_tags_field.fill_in with: "clearance, discount"

    # Submit the form
    click_button "Update Product"

    # Verify success message
    expect(page).to have_content("Product was successfully updated")

    # Verify tags were persisted
    product.reload
    expect(product.shopify_info.tag_list.to_s).to eq("featured, new-arrival, sale")
    expect(product.woo_info.tag_list.to_s).to eq("clearance, discount")
  end

  scenario "edits existing store_info tags when they already have tags", :js do # rubocop:todo RSpec/MultipleExpectations
    # Set initial tags
    product.shopify_info.tag_list.add("old-tag-1", "old-tag-2")
    product.woo_info.tag_list.add("legacy-tag")
    product.shopify_info.save
    product.woo_info.save

    visit edit_product_path(product)

    # Verify page loads with existing tags
    shopify_section = find(".store-info-fields", text: "Shopify")
    shopify_tags_field = shopify_section.find_field("Tags")

    expect(shopify_tags_field.value).to eq("old-tag-1, old-tag-2")

    # Update tags (replace existing ones)
    shopify_tags_field.fill_in with: "updated-tag-1, updated-tag-2"

    click_button "Update Product"

    expect(page).to have_content("Product was successfully updated")

    # Verify tags were updated
    product.reload
    expect(product.shopify_info.tag_list.to_s).to eq("updated-tag-1, updated-tag-2")
    expect(product.shopify_info.tag_list).not_to include("old-tag-1", "old-tag-2")
  end

  scenario "adds a new store_info to product", :js do # rubocop:todo RSpec/MultipleExpectations
    visit edit_product_path(product_with_one_store)

    # Verify page loads and shows store information section
    expect(page).to have_content("Store Information")

    # Verify only Shopify store_info is displayed (Woo was removed)
    expect(page).to have_content("Shopify")
    expect(page).not_to have_content("Woo")

    # Click Add Store Info button
    click_button "Add Store Info"

    # Verify new store info form appears
    expect(page).to have_content("New Store Info")

    # Find the newly added store info fields
    new_store_section = find(".store-info-fields", text: "New Store Info")

    # Select Woo from the dropdown
    # The select element is hidden by slim-select, so we need to find it with visible: false
    store_select = new_store_section.find("select[name$='[store_name]']", visible: :all)
    page.execute_script("arguments[0].value = 'woo'", store_select)

    # Fill in tags for the new store_info
    new_store_section.fill_in "Tags", with: "woo-exclusive, special-offer"

    # Submit the form
    click_button "Update Product"

    # Verify success message
    expect(page).to have_content("Product was successfully updated")

    # Verify new store_info was created with correct data
    product_with_one_store.reload
    expect(product_with_one_store.store_infos.count).to eq(2)
    expect(product_with_one_store.woo_info).to be_present
    expect(product_with_one_store.woo_info.tag_list.to_s).to eq("woo-exclusive, special-offer")
  end
end
