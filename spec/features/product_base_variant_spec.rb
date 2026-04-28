# frozen_string_literal: true

require "rails_helper"

# rubocop:disable RSpec/MultipleExpectations
RSpec.describe "Product base variant creation" do
  before { sign_in_as_admin }
  after { log_out }

  scenario "creates a base variant when the blank variant form is submitted", :js do
    franchise = create(:franchise)

    visit new_product_path

    fill_in "Title", with: "Base Variant Product"

    franchise_select = find("select[name='product[franchise_id]']", visible: :all)
    page.execute_script("arguments[0].value = arguments[1]", franchise_select, franchise.id.to_s)

    expect(find("select[name='product[shape]']", visible: :all).value).to eq(Product.default_shape)

    click_button "Create Product"

    expect(page).to have_content("Product was successfully created")

    product = Product.find_by!(title: "Base Variant Product")
    expect(page).to have_current_path(product_path(product))
    expect(product.variants.count).to eq(1)
    expect(product.base_variant).to be_present
    expect(product.base_variant.size_id).to be_nil
    expect(product.base_variant.version_id).to be_nil
    expect(product.base_variant.color_id).to be_nil
    expect(product.base_variant.sku).to be_present
  end

  scenario "creates a base variant even when the blank variant form is removed", :js do
    franchise = create(:franchise)

    visit new_product_path

    fill_in "Title", with: "Removed Blank Variant Product"

    franchise_select = find("select[name='product[franchise_id]']", visible: :all)
    page.execute_script("arguments[0].value = arguments[1]", franchise_select, franchise.id.to_s)

    expect(find("select[name='product[shape]']", visible: :all).value).to eq(Product.default_shape)

    within all(".variant-fields").first do
      click_link "Remove"
    end

    expect(page).to have_no_css(".variant-fields")

    click_button "Create Product"

    expect(page).to have_content("Product was successfully created")

    product = Product.find_by!(title: "Removed Blank Variant Product")
    expect(page).to have_current_path(product_path(product))
    expect(product.variants.count).to eq(1)
    expect(product.base_variant).to be_present
    expect(product.base_variant.size_id).to be_nil
    expect(product.base_variant.version_id).to be_nil
    expect(product.base_variant.color_id).to be_nil
    expect(product.base_variant.sku).to be_present
  end
end
# rubocop:enable RSpec/MultipleExpectations
