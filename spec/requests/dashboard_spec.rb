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
    it "renders the page without waiting for the debt reports", :aggregate_failures do
      sell(batman)

      get root_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Dashboard/Index")
      expect(inertia).to have_deferred_props(:sale_debts, group: :sale_debts)
      expect(inertia).to have_deferred_props(:supplier_debts, group: :supplier_debts)
      expect(inertia.props).not_to include(:sale_debts, :supplier_debts)
    end

    it "loads unpurchased sold products and suppliers with debts after the page", :aggregate_failures do
      sell(asuka)
      sell(batman, qty: 2)
      sell(guts)
      create(:purchase, product: asuka, amount: 1, supplier: supplier_fnc)
      create(:purchase, product: batman, amount: 1, supplier: supplier_agk)

      get root_path
      inertia_load_deferred_props

      expect(inertia.props[:sale_debts][:rows].pluck(:title)).to contain_exactly(batman.full_title, guts.full_title)
      expect(inertia.props[:sale_debts][:count]).to eq(2)
      expect(inertia.props[:supplier_debts][:rows].pluck(:supplier_title)).to contain_exactly("FNC", "AnitoysGK")
      expect(inertia.props[:supplier_debts][:total]).to be_present
    end

    it "reports each supplier's purchase count, cost, payments, and debt", :aggregate_failures do
      purchase = create(:purchase, supplier: supplier_fnc, amount: 1)
      create(:payment, purchase:, value: 10)

      get root_path
      inertia_load_deferred_props(:supplier_debts)

      expect(inertia.props[:supplier_debts][:rows].sole).to include(
        supplier_title: "FNC", total_size: 1, total_cost: be_present, paid: be_present, total_debt: be_present
      )
      expect(inertia.props).not_to include(:sale_debts)
    end
  end

  describe "GET /debts" do
    it "lists unpurchased sold products without a search query", :aggregate_failures do
      sell(batman)

      get debts_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Dashboard/Debts")
      expect(inertia.props[:debts].pluck(:title)).to eq([batman.full_title])
    end

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

  describe "POST /pull-last-orders" do
    it "enqueues the Woo sync, re-enables the sales hook, and redirects back with a notice", :aggregate_failures do
      allow(Woo::PullSalesJob).to receive(:perform_later).with(pages: 2, requested_by: admin)
      allow(Config).to receive(:enable_sales_hook)

      post last_orders_pull_path, headers: {"Referer" => "http://www.example.com/dashboard"}

      expect(Woo::PullSalesJob).to have_received(:perform_later).with(pages: 2, requested_by: admin)
      expect(Config).to have_received(:enable_sales_hook)
      expect(response).to redirect_to("http://www.example.com/dashboard")
      expect(flash[:notice]).to eq("Started getting missing sales. It takes about 5–10 minutes. You'll get a notification when it finishes.")
    end
  end
end
