# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Variant assignment repairs" do
  before { sign_in_as_admin }
  after { log_out }

  scenario "shows a real inline error, then reloads away a repaired row", :js do
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
    invalid_variant = create(:product).base_variant

    visit variant_assignment_issues_path

    within("tr[aria-label='BROKEN-42']") do
      click_button "Edit"
      page.execute_script(<<~JS)
        const select = document.querySelector('[aria-label="Variant for BROKEN-42"]');
        const option = document.createElement("option");
        option.value = "#{invalid_variant.id}";
        option.textContent = "Invalid Variant";
        option.selected = true;
        select.appendChild(option);
        select.dispatchEvent(new Event("change", { bubbles: true }));
      JS
      click_button "Save"

      expect(page).to have_text("Variant is not an available repair candidate")
      expect(page).to have_field("Variant for BROKEN-42")

      select historical_variant.assignment_label, from: "Variant for BROKEN-42"
      click_button "Save"
    end

    expect(page).to have_text("No Variant assignment issues")
    expect(page).to have_no_selector("tr[aria-label='BROKEN-42']")
    expect(page).to have_current_path(variant_assignment_issues_path)
  end
end
