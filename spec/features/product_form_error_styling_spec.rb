# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Product form error styling" do
  before { sign_in_as_admin }
  after { log_out }

  scenario "keeps the supplier error absolute and the select border red on invalid purchase submit", :js do
    franchise = create(:franchise)
    create(:warehouse, is_default: true)

    visit new_product_path

    fill_in "Title", with: "Styled Error Product"
    choose_react_select(franchise.title, from: "Franchise")
    click_button "Add Purchase"

    expect {
      click_button "Create Product"
    }.not_to change(Product, :count)

    error_wrapper = all(".purchase-fields .field_with_errors").first
    expect(error_wrapper.find(".text_error", visible: :all)[:class]).to include("absolute")
    expect(
      page.evaluate_script(
        "getComputedStyle(document.querySelector('.purchase-fields .field_with_errors .rs__control')).borderTopColor",
      ),
    ).to match(/185, 28, 28|0\.505|oklch/)
  end
end
