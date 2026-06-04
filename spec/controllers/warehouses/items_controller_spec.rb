# frozen_string_literal: true

require "rails_helper"

RSpec.describe Warehouses::ItemsController do
  before { sign_in_as_admin }
  after { log_out }

  let(:warehouse) { create(:warehouse) }

  describe "GET #new" do
    it "renders the Inertia new component with warehouse-scoped form props" do
      get :new, params: {warehouse_id: warehouse.id}

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect_inertia.to render_component("PurchaseItems/New")
        expect(inertia.props[:purchase_item][:warehouse_id]).to eq(warehouse.id)
        expect(inertia.props[:form_action]).to end_with("/warehouses/#{warehouse.id}/items")
        expect(inertia.props[:cancel_path]).to end_with("/warehouses/#{warehouse.id}")
      end
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
