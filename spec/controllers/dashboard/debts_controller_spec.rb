# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dashboard::DebtsController, type: :controller do
  before { sign_in_as_admin }
  after { log_out }

  describe "GET #show" do
    let!(:unpaid_purchases) { create_list(:purchase, 3, :unpaid) }

    it "returns successful response" do
      get :show
      expect(response).to be_successful
      expect(assigns[:unpaid_purchases]).to be_present
    end

    it "preloads suppliers for unpaid purchases" do
      get :show
      unpaid_purchases = assigns[:unpaid_purchases]

      unpaid_purchases.each do |purchase|
        expect(purchase.association(:supplier)).to be_loaded
      end
    end

    it "assigns debts variable" do
      get :show
      expect(assigns[:debts]).not_to be_nil
      expect(assigns[:debts]).to respond_to(:each)
    end

    context "with search query" do
      let!(:product) { create(:product, title: "Special Product") }
      let!(:customer) { create(:customer, email: "customer@example.com") }
      let!(:sale) { create(:sale, customer:, status: "processing") }
      let!(:sale_item) { create(:sale_item, sale:, product:, qty: 2) }

      it "filters debts by product title" do
        get :show, params: {q: "special"}
        expect(assigns[:debts]).to be_present
      end

      it "returns all debts without search query" do
        get :show
        expect(assigns[:debts]).to be_present
      end
    end
  end
end
