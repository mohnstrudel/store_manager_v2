# frozen_string_literal: true

require "rails_helper"

RSpec.describe Warehouses::ItemsController, type: :controller do
  before { sign_in_as_admin }
  after { log_out }

  let(:warehouse) { create(:warehouse) }

  describe "GET #new" do
    it "renders the purchase item form in warehouse context" do
      get :new, params: {warehouse_id: warehouse.id}

      expect(response).to be_successful
      expect(assigns[:warehouse]).to eq(warehouse)
      expect(assigns[:purchase_item]).to be_a_new(PurchaseItem)
    end
  end

  describe "POST #create" do
    let(:purchase) { create(:purchase) }

    it "creates a purchase item and redirects to the warehouse" do
      expect {
        post :create, params: {
          warehouse_id: warehouse.id,
          purchase_item: {
            warehouse_id: warehouse.id,
            purchase_id: purchase.id,
            weight: 1,
            length: 1,
            width: 1,
            height: 1,
            expenses: "9.99",
            shipping_cost: "9.99"
          }
        }
      }.to change(PurchaseItem, :count).by(1)

      expect(response).to redirect_to(warehouse_path(warehouse))
    end
  end
end
