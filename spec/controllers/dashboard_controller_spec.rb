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
          create(:payment, purchase: purchase, amount: 10.0)
        end
      end
    end

    it "calculates supplier debts without N+1 queries" do
      # Should preload associations and use in-memory calculations
      expect { get :index }
        .to make_database_queries(count: 3) # 1 for suppliers with includes, minimal additional queries
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
  end

  describe "GET #debts" do
    let!(:unpaid_purchases) { create_list(:purchase, 3, :unpaid) }

    it "preloads suppliers for unpaid purchases" do
      expect { get :debts }
        .to make_database_queries(count: <= 10) # Should include suppliers in query
    end

    it "returns successful response" do
      get :debts
      expect(response).to be_successful
      expect(assigns[:unpaid_purchases]).to be_present

      # Verify suppliers are preloaded
      unpaid_purchases = assigns[:unpaid_purchases]
      unpaid_purchases.each do |purchase|
        expect(purchase.association(:supplier)).to be_loaded
      end
    end
  end

  describe "Purchase model optimizations" do
    let!(:purchase) { create(:purchase) }
    let!(:purchase_items) { create_list(:purchase_item, 3, purchase: purchase, shipping_price: 5.0) }

    it "calculates total_shipping without N+1 queries when purchase_items are preloaded" do
      # Preload the association
      purchase_with_items = Purchase.includes(:purchase_items).find(purchase.id)

      # Should not trigger additional queries for total_shipping
      expect { purchase_with_items.total_shipping }
        .not_to make_database_queries
    end

    it "calculates total_shipping correctly" do
      purchase_with_items = Purchase.includes(:purchase_items).find(purchase.id)
      expect(purchase_with_items.total_shipping).to eq(15.0) # 3 items * $5 each
    end
  end
end
