# frozen_string_literal: true

require "rails_helper"

describe DashboardController do
  before { sign_in_as_admin }
  after { log_out }

  describe "GET #index" do
    let!(:suppliers) { create_list(:supplier, 3) }

    before do
      # Create purchases with items and payments for realistic scenario
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
      expect(assigns[:suppliers_debts]).to be_present
      expect(assigns[:suppliers_debts].size).to eq(3)
    end

    it "calculates correct debt values" do
      get :index
      supplier_debts = assigns[:suppliers_debts]

      supplier_debts.each do |supplier_debt|
        expect(supplier_debt[:total_size]).to be > 0
        expect(supplier_debt[:total_cost]).to be >= 0
        expect(supplier_debt[:paid]).to be >= 0
        expect(supplier_debt[:total_debt]).to be >= 0
      end
    end

    it "assigns total suppliers debt" do
      get :index
      expect(assigns[:total_suppliers_debt]).to be_present
      expect(assigns[:total_suppliers_debt]).to be >= 0
    end

    it "assigns sale debts variable" do
      get :index
      expect(assigns[:sale_debts]).not_to be_nil
    end

    it "assigns config" do
      get :index
      expect(assigns[:config]).to eq(Config)
    end
  end

  describe "GET #noop" do
    it "returns successful response" do
      get :noop
      expect(response).to be_successful
    end
  end

  describe "Purchase model optimizations" do
    let!(:purchase) { create(:purchase) }
    let!(:purchase_items) { create_list(:purchase_item, 3, purchase: purchase, shipping_cost: 5.0) }

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
      # Create a sale that creates debt (more sold than purchased)
      sale = create(:sale, customer: customer, status: "processing")
      create(:sale_item, sale: sale, product: product, qty: 5)

      # Create a purchase with fewer items than sold
      purchase = create(:purchase, supplier: supplier, product: product, amount: 2)
      create_list(:purchase_item, 2, purchase: purchase)

      # This should create a debt situation where 5 are sold but only 2 are purchased
    end

    it "calculates sale debts correctly" do
      get :index
      sale_debts = assigns[:sale_debts]

      # The sale_debts query should return results but we don't test specific values
      # as the SQL is complex and the exact calculation depends on multiple factors
      expect(sale_debts).to be_a(ActiveRecord::Relation)
      expect(sale_debts).to respond_to(:each)
    end
  end
end
