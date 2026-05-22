# frozen_string_literal: true

require "rails_helper"

# rubocop:disable RSpec/MultipleExpectations
RSpec.describe "Editing a product" do
  before { sign_in_as_admin }

  scenario "updates the title and redirects to the show page", :js do
    product = create(:product)

    visit edit_product_path(product)
    fill_in "Title", with: "Refreshed Title"
    click_button "Update Product"

    expect(page).to have_content("Product was successfully updated")
    expect(page).to have_current_path(product_path(product.reload))
  end

  scenario "re-renders edit with a top-level error notice when title is blank", :js do
    product = create(:product)

    visit edit_product_path(product)
    fill_in "Title", with: ""
    click_button "Update Product"

    expect(page).to have_current_path(edit_product_path(product))
    expect(page).to have_content("Fix errors and try again")
    expect(page).to have_content("Title")
    expect(page).to have_content("can't be blank")
  end

  scenario "routes a duplicate-SKU error to the variant field, not the notice banner", :js do
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
    within all(".variant-fields").first do
      expect(page).to have_content("has already been taken")
    end
    expect(page).not_to have_content("Variants 0 sku")
  end
end
# rubocop:enable RSpec/MultipleExpectations
