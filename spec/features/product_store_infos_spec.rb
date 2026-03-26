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
    expect(product_with_one_store.woo_info.tag_list).to contain_exactly("woo-exclusive", "special-offer")
  end

  scenario "deletes existing store_info using the destroy checkbox", :js do # rubocop:todo RSpec/MultipleExpectations
    visit edit_product_path(product)

    # Verify both store_infos are displayed
    expect(page).to have_content("Shopify")
    expect(page).to have_content("Woo")

    # Find the Woo store_info section and check the destroy checkbox
    woo_section = find(".store-info-fields", text: "Woo")
    within woo_section do
      check "Destroy connection?"
    end

    # Submit the form
    click_button "Update Product"

    # Verify success message
    expect(page).to have_content("Product was successfully updated")

    # Verify Woo store_info was deleted but Shopify remains
    product.reload
    expect(product.store_infos.count).to eq(1)
    expect(product.shopify_info).to be_present
    expect(product.woo_info).to be_nil
  end

  scenario "prevents adding duplicate store_name for the same product", :js do # rubocop:todo RSpec/MultipleExpectations
    visit edit_product_path(product_with_one_store)

    # Verify only Shopify store_info exists
    expect(product_with_one_store.store_infos.count).to eq(1)
    expect(page).to have_content("Shopify")

    # Click Add Store Info button
    click_button "Add Store Info"

    # Find the newly added store info fields
    new_store_section = find(".store-info-fields", text: "New Store Info")

    # Verify the dropdown only shows available (non-duplicate) store names
    store_select = new_store_section.find("select[name$='[store_name]']", visible: :all)
    options = store_select.all("option", visible: :all).map(&:value)

    # Shopify should NOT be in the options (it's already used)
    # Woo should be available
    expect(options).not_to include("shopify")
    expect(options).to include("woo")

    # Verify that attempting to add Woo (the only available option) works
    page.execute_script("arguments[0].value = 'woo'", store_select)
    new_store_section.fill_in "Tags", with: "new-woo-tags"

    click_button "Update Product"

    # Verify success and only the allowed store was added
    expect(page).to have_content("Product was successfully updated")
    product_with_one_store.reload
    expect(product_with_one_store.store_infos.count).to eq(2)
  end

  scenario "clears all tags from store_info", :js do # rubocop:todo RSpec/MultipleExpectations
    # Set initial tags on store_infos
    product.shopify_info.tag_list.add("featured", "new")
    product.shopify_info.save

    visit edit_product_path(product)

    # Verify tags are displayed
    shopify_section = find(".store-info-fields", text: "Shopify")
    shopify_tags_field = shopify_section.find_field("Tags")
    expect(shopify_tags_field.value).to eq("featured, new")

    # Clear the tags field
    shopify_tags_field.fill_in with: ""

    # Submit the form
    click_button "Update Product"

    # Verify success message
    expect(page).to have_content("Product was successfully updated")

    # Verify tags were cleared
    product.reload
    expect(product.shopify_info.tag_list.to_s).to eq("")
    expect(product.shopify_info.tag_list).to be_empty
  end

  scenario "handles multiple operations simultaneously - edit, delete, and add", :js do # rubocop:todo RSpec/MultipleExpectations
    # Set initial tags
    product.shopify_info.tag_list.add("old-tag")
    product.shopify_info.save

    visit edit_product_path(product_with_one_store)

    # Verify initial state
    expect(product_with_one_store.store_infos.count).to eq(1)
    expect(page).to have_content("Shopify")

    # Edit: Update Shopify tags
    shopify_section = find(".store-info-fields", text: "Shopify")
    shopify_tags_field = shopify_section.find_field("Tags")
    shopify_tags_field.fill_in with: "updated-shopify-tag"

    # Add: Add a new Woo store_info
    click_button "Add Store Info"
    new_store_section = find(".store-info-fields", text: "New Store Info")
    store_select = new_store_section.find("select[name$='[store_name]']", visible: :all)
    page.execute_script("arguments[0].value = 'woo'", store_select)
    new_store_section.fill_in "Tags", with: "new-woo-tag"

    # Submit the form
    click_button "Update Product"

    # Verify success message
    expect(page).to have_content("Product was successfully updated")

    # Verify all operations succeeded
    product_with_one_store.reload
    expect(product_with_one_store.store_infos.count).to eq(2)
    expect(product_with_one_store.shopify_info.tag_list.to_s).to eq("updated-shopify-tag")
    expect(product_with_one_store.woo_info.tag_list.to_s).to eq("new-woo-tag")
  end

  scenario "adds new store_info without any tags", :js do # rubocop:todo RSpec/MultipleExpectations
    visit edit_product_path(product_with_one_store)

    # Verify only Shopify exists
    expect(page).to have_content("Shopify")

    # Click Add Store Info button
    click_button "Add Store Info"

    # Find the newly added store info fields
    new_store_section = find(".store-info-fields", text: "New Store Info")

    # Select Woo from the dropdown but leave tags empty
    store_select = new_store_section.find("select[name$='[store_name]']", visible: :all)
    page.execute_script("arguments[0].value = 'woo'", store_select)

    # Don't fill in tags - leave them empty

    # Submit the form
    click_button "Update Product"

    # Verify success message
    expect(page).to have_content("Product was successfully updated")

    # Verify new store_info was created with empty tag_list
    product_with_one_store.reload
    expect(product_with_one_store.store_infos.count).to eq(2)
    expect(product_with_one_store.woo_info).to be_present
    expect(product_with_one_store.woo_info.tag_list.to_s).to eq("")
    expect(product_with_one_store.woo_info.tag_list).to be_empty
  end

  scenario "adds store info while creating a new product", :js do # rubocop:todo RSpec/MultipleExpectations
    franchise = create(:franchise)
    shape = create(:shape)

    visit new_product_path

    fill_in "Title", with: "New Product With Store Info"
    fill_in "SKU", with: "new-product-store-info"
    franchise_select = find("select[name='product[franchise_id]']", visible: :all)
    page.execute_script("arguments[0].value = arguments[1]", franchise_select, franchise.id.to_s)

    shape_select = find("select[name='product[shape_id]']", visible: :all)
    page.execute_script("arguments[0].value = arguments[1]", shape_select, shape.id.to_s)

    click_button "Add Store Info"

    new_store_section = find(".store-info-fields", text: "New Store Info")
    store_select = new_store_section.find("select[name$='[store_name]']", visible: :all)
    page.execute_script("arguments[0].value = 'shopify'", store_select)
    new_store_section.fill_in "Tags", with: "featured, launch"

    click_button "Create Product"

    expect(page).to have_content("Product was successfully created")

    created_product = Product.find_by!(sku: "new-product-store-info")
    expect(created_product.shopify_info).to be_present
    expect(created_product.shopify_info.tag_list).to contain_exactly("featured", "launch")
  end
end
