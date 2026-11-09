# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Broken sales" do
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

    visit broken_sales_path

    within("tr[aria-label='BROKEN-42']") do
      click_button "Edit"
      select "#{historical_variant.title} (Historical)", from: "Variant for BROKEN-42"
      click_button "Save"
    end

    expect(page).to have_text("No Variant assignment issues")
    expect(page).to have_no_selector("tr[aria-label='BROKEN-42']")
    expect(page).to have_current_path(broken_sales_path)
  end

  scenario "fixes the Variant of an order line, then the row leaves Orders", :js do
    product = create(:product)
    variant = create(:variant, :with_color, product:, color_value: "Red")
    sale = create(:sale, status: "processing", shopify_id: nil, woo_store_id: "4242")
    line = create(:sale_item, sale:, product:, variant:)
    line.update_columns(variant_id: nil)
    Sale::ImportFailure.record(
      store_name: "woo", store_order_id: "4242", message: "Import failed", sentry_event_id: "abc123", failed_at: Time.current
    )
    reference = "Order 4242, item #{line.id}"

    visit sales_path
    find("a[aria-label='Broken, 2 problems']").click

    within("tr[aria-label='#{reference}']") do
      expect(page).to have_css(
        "a[aria-label='Open Woo order 4242 in Sentry'][href='https://handsomecake-goodies.sentry.io/issues/?query=abc123']"
      )
      click_button "Edit"
      select variant.title, from: "Variant for #{reference}"
      click_button "Save"
    end

    expect(page).to have_no_selector("tr[aria-label='#{reference}']")
    expect(line.reload.variant).to eq(variant)
  end
end
