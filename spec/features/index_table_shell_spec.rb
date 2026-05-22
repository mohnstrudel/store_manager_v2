# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Index table shells", :js do
  before { sign_in_as_admin }
  after { log_out }

  let!(:customer) { create(:customer, first_name: "Dale", last_name: "Cooper") }
  let!(:product) { create(:product, title: "Pikachu") }
  let!(:supplier) { create(:supplier, title: "Berlin Imports") }
  let!(:sale) { create(:sale, customer:) }
  let!(:variant) { create(:variant, product:) }
  let!(:sale_item) { create(:sale_item, sale:, product:, variant:) }
  let!(:purchase) { create(:purchase, product:, supplier:) }

  it "keeps the sales index table direct inside the bordered shell" do
    visit sales_path

    within ".section-border-base" do
      expect(page).to have_css("table[role='grid']")
      expect(page).not_to have_css(".table-card")
    end
  end

  it "keeps the purchases index table direct inside the bordered shell" do
    visit purchases_path

    within ".section-border-base" do
      expect(page).to have_css("table[role='grid']")
      expect(page).not_to have_css(".table-card")
    end
  end
end
