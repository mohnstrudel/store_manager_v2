# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Product copy buttons" do
  before { sign_in_as_admin }

  scenario "shows copy buttons for Woo ID and Shopify ID when store ids are present", :js do
    product = create(:product)
    product.woo_info.update!(store_id: "99000")
    product.shopify_info.update!(store_id: "gid://shopify/Product/10166608396617")

    visit product_path(product)

    expect(page).to have_css('[data-copy-to-clipboard-text-value="99000"]', text: "Copy")
    expect(page).to have_css('[data-copy-to-clipboard-text-value="10166608396617"]', text: "Copy")
  end

  scenario "hides copy buttons when store ids are missing", :js do
    product = create(:product)
    product.woo_info.update!(store_id: nil)
    product.shopify_info.update!(store_id: nil)

    visit product_path(product)

    expect(page).to have_no_css('[data-copy-to-clipboard-text-value=""]')
    expect(page).to have_no_button("Copy")
  end
end
