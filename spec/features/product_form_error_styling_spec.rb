# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Product form error styling" do
  before { sign_in_as_admin }

  scenario "keeps the supplier error absolute and the select border red on invalid purchase submit", :js do # rubocop:disable RSpec/MultipleExpectations
    franchise = create(:franchise)
    create(:warehouse, is_default: true)

    visit new_product_path

    fill_in "Title", with: "Styled Error Product"
    choose_react_select(franchise.title, from: "Franchise")
    click_button "Add Purchase"

    click_button "Create Product"

    expect(page).to have_content("Fix errors and try again")
    expect(Product.count).to eq(0)
    within ".purchase-fields" do
      expect(page).to have_content("Supplier")
      expect(page).to have_content("can't be blank")
    end
    expect(page).to have_css(".purchase-fields .field_with_errors .text_error.absolute", visible: :all)
    expect(
      page.evaluate_script(
        "getComputedStyle(document.querySelector('.purchase-fields .field_with_errors .rs__control')).borderTopColor"
      )
    ).to match(/185, 28, 28|0\.505|oklch/)
  end
end
