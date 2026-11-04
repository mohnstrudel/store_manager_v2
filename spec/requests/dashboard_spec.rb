# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard" do
  before { sign_in_as_admin }

  let(:asuka) { create(:product, title: "Asuka") }
  let(:batman) { create(:product, title: "Batman") }
  let(:guts) { create(:product, title: "Guts") }
  let(:supplier_fnc) { create(:supplier, title: "FNC") }
  let(:supplier_agk) { create(:supplier, title: "AnitoysGK") }

  def sell(product, qty: 1)
    create(:sale_item, sale: create(:sale, status: "processing"), product:, variant: nil, qty:)
  end

  describe "GET /" do
    it "lists unpurchased sold products and suppliers with debts", :aggregate_failures do
      sell(asuka)
      sell(batman, qty: 2)
      sell(guts)
      create(:purchase, product: asuka, amount: 1, supplier: supplier_fnc)
      create(:purchase, product: batman, amount: 1, supplier: supplier_agk)

      get root_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Dashboard/Index")
      expect(inertia.props[:sale_debts].pluck(:title)).to contain_exactly(batman.full_title, guts.full_title)
      expect(inertia.props[:suppliers_debts].pluck(:supplier_title)).to contain_exactly("FNC", "AnitoysGK")
    end
  end

  describe "GET /debts" do
    it "filters debts by product title", :aggregate_failures do
      sell(batman)
      sell(guts)

      get debts_path, params: {q: "Batman"}

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Dashboard/Debts")
      expect(inertia.props[:debts].pluck(:title)).to eq([batman.full_title])
      expect(inertia.props[:search]).to eq("q" => "Batman")
    end

    it "finds a product by its new franchise after the product changes", :aggregate_failures do
      sell(batman, qty: 2)
      sell(batman, qty: 4)
      dc_comics = create(:franchise, title: "DC Comics")

      patch product_path(batman), params: {
        product: {title: batman.title, franchise_id: dc_comics.id, shape: batman.shape}
      }
      get debts_path, params: {q: "DC Comics"}

      debt = inertia.props[:debts].sole
      expect(debt[:title]).to eq(batman.reload.full_title)
      expect(debt[:title]).to include("DC Comics")
      expect(debt[:sold_amount]).to eq(6)
    end
  end
end
