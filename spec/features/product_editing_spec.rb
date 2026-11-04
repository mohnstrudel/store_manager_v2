# frozen_string_literal: true

require "rails_helper"

# rubocop:disable RSpec/MultipleExpectations
RSpec.describe "Editing a product" do
  before { sign_in_as_admin }

  scenario "routes a duplicate-SKU error to the variant field and keeps its header aligned", :js do
    other = create(:product)
    other.variants.first.update!(sku: "DUPLICATE-SKU")
    product = create(:product)

    visit edit_product_path(product)

    within all(".variant-fields").first do
      fill_in "SKU", with: "DUPLICATE-SKU"
    end

    click_button "Update Product"

    expect(page).to have_current_path(edit_product_path(product))
    expect(page).to have_content("Fix errors and try again")
    expect(page).to have_css(".variant-fields", text: "has already been taken")
    error = find(".variant-fields .text_error", text: "has already been taken", visible: :all)
    expect(error[:class]).to include("absolute")
    expect(
      page.evaluate_script(
        "getComputedStyle(document.querySelector('.variant-fields input[name=\"variants[0][sku]\"]')).borderTopColor"
      )
    ).to match(/185, 28, 28|0\.505|oklch/)
    expect(page).not_to have_content("Variants 0 sku")
    expect(
      page.evaluate_script(
        "getComputedStyle(document.querySelector('.variant-fields .form_section_item_header')).alignItems"
      )
    ).to eq("center")
  end
end
# rubocop:enable RSpec/MultipleExpectations
