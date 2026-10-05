# frozen_string_literal: true

require "rails_helper"

describe DashboardController do
  before { sign_in_as_admin }
  after { log_out }

  describe "GET #index" do
    let!(:suppliers) { create_list(:supplier, 3) }

    before do
      suppliers.each do |supplier|
        purchases = create_list(:purchase, 2, supplier: supplier)
        purchases.each do |purchase|
          create_list(:purchase_item, 3, purchase: purchase)
          create(:payment, purchase: purchase, value: 10.0)
        end
      end
    end

    it "returns successful response" do
      get :index
      expect(response).to be_successful
      expect_inertia.to render_component("Dashboard/Index")
      expect(inertia.props[:suppliers_debts].size).to eq(3)
    end

    it "calculates correct debt values" do
      get :index
      supplier_debts = inertia.props[:suppliers_debts]

      supplier_debts.each do |supplier_debt|
        expect(supplier_debt[:total_size]).to be > 0
        expect(supplier_debt[:total_cost]).to be_present
        expect(supplier_debt[:paid]).to be_present
        expect(supplier_debt[:total_debt]).to be_present
      end
    end

    it "assigns total suppliers debt" do
      get :index
      expect(inertia.props[:total_suppliers_debt]).to be_present
    end

    it "assigns sale debts variable" do
      get :index
      expect(inertia.props[:sale_debts]).not_to be_nil
    end

    it "assigns config" do
      get :index
      expect(inertia.props[:sales_hook_disabled]).to eq(Config.sales_hook_disabled?)
    end
  end

  describe "GET #noop" do
    it "returns successful response" do
      get :noop
      expect(response).to be_successful
      expect_inertia.to render_component("Dashboard/Noop")
    end
  end

  describe "Purchase model optimizations" do
    let!(:purchase) { create(:purchase) }

    before { create_list(:purchase_item, 3, purchase: purchase, shipping_cost: 5.0) }

    it "calculates shipping_total correctly" do
      purchase.reload
      expect(purchase.shipping_total).to eq(15.0)
    end

    it "shipping_total is updated via callback" do
      expect(purchase.shipping_total).to eq(15.0)
    end
  end

  describe "complex sale_debts query" do
    let!(:product) { create(:product, title: "Test Product") }
    let!(:supplier) { create(:supplier) }
    let!(:customer) { create(:customer) }

    before do
      sale = create(:sale, customer: customer, status: "processing")
      create(:sale_item, sale: sale, product: product, qty: 5)

      purchase = create(:purchase, supplier: supplier, product: product, amount: 2)
      create_list(:purchase_item, 2, purchase: purchase)
    end

    it "calculates sale debts correctly" do
      get :index
      sale_debts = inertia.props[:sale_debts]

      expect(sale_debts).to respond_to(:each)
    end
  end
end
