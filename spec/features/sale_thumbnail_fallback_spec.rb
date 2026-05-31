# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sale thumbnail fallback", :js do
  before { sign_in_as_admin }

  after { log_out }

  scenario "shows an unavailable image placeholder on the sale show page" do
    product = create(:product)
    sale = create(:sale)
    create(:sale_item, sale:, product:, variant: nil, qty: 1)

    visit sale_path(sale)

    within ".table_card" do
      expect(page).to have_text("Image unavailable")
      expect(page).to have_no_css("img.preloadable_img__img", visible: :all)
    end
  end
end
