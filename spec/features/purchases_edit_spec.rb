# frozen_string_literal: true

require "rails_helper"

describe "Purchase editing", js: true do
  before { sign_in_as_admin }
  after { log_out }

  let!(:warehouse) { create(:warehouse, is_default: true) }
  let!(:supplier) { create(:supplier) }

  it "shows the existing variant pre-selected when loading the edit form" do
    product = create(:product)
    variant = create(:variant, product:)
    purchase = create(:purchase, product:, variant:, supplier:)

    visit edit_purchase_path(purchase)

    expect(page).to have_text(variant.title)
  end

  it "auto-selects the first variant when switching to a new product" do
    purchase = create(:purchase, supplier:)
    new_product = create(:product)

    visit edit_purchase_path(purchase)
    choose_react_select(new_product.build_full_title_with_shop_id, from: "Product")

    # Every product has a base model variant auto-created first, so it gets auto-selected
    expect(page).to have_text("Base Model")
  end
end
