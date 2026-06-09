# frozen_string_literal: true

require "rails_helper"

feature "New sale form" do
  before { sign_in_as_admin }
  after { log_out }

  scenario "shows validation errors when submitted untouched", :js do
    visit new_sale_path

    expect(page).to have_button("Create Sale")

    expect {
      click_button "Create Sale"
    }.not_to change(Sale, :count)

    expect(page).to have_current_path(new_sale_path, ignore_query: true)
    expect(page).to have_content("Fix errors and try again")
  end
end
