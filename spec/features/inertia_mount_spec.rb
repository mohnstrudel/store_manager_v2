# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Inertia mount", :js do
  before { sign_in_as_admin }

  scenario "renders the Sizes pilot page in the browser", :aggregate_failures do
    create(:size, value: "1:6")

    visit sizes_path

    expect(page).to have_link("Add New Record", href: new_size_path)
    expect(page).to have_content("1:6")
  end
end
