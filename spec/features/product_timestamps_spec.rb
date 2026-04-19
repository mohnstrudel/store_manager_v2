# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Product Timestamps" do
  before { sign_in_as_admin }

  scenario "shows created and updated timestamps for each available store", :js do
    product = create(:product)
    product.woo_info.destroy!

    product.update_columns( # rubocop:disable Rails/SkipsModelValidations
      created_at: Time.zone.parse("2026-04-19 09:00"),
      updated_at: Time.zone.parse("2026-04-21 14:00")
    )

    product.shopify_info.update!(
      ext_created_at: Time.zone.parse("2026-04-20 10:00"),
      ext_updated_at: Time.zone.parse("2026-04-22 11:00")
    )

    visit product_path(product)

    expect(page).to have_text(/StoreMate/i)
    expect(page).to have_text("19. Apr ’26")
    expect(page).to have_text("20. Apr ’26")
    expect(page).to have_text("21. Apr ’26")
    expect(page).to have_text("22. Apr ’26")
  end
end
