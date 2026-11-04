# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Variant assignment repairs" do
  before { sign_in_as_admin }

  scenario "repairs a row inline, then reloads it away", :js do
    product = create(:product)
    active_variant = create(:variant, :with_version, product:, version_value: "Active")
    historical_variant = create(:variant, :with_color, product:, color_value: "Archive")
    purchase = create(
      :purchase,
      product:,
      variant: active_variant,
      order_reference: "BROKEN-42"
    )
    historical_variant.update!(deactivated_at: Time.current)
    purchase.update_columns(variant_id: nil)

    visit variant_assignment_issues_path

    within("tr[aria-label='BROKEN-42']") do
      click_button "Edit"
      select "#{historical_variant.title} (Historical)", from: "Variant for BROKEN-42"
      click_button "Save"
    end

    expect(page).to have_text("No Variant assignment issues")
    expect(page).to have_no_selector("tr[aria-label='BROKEN-42']")
    expect(page).to have_current_path(variant_assignment_issues_path)
  end
end
