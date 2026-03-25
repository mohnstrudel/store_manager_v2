# frozen_string_literal: true

require "rails_helper"

RSpec.describe Purchases::MovesController, type: :controller do
  before { sign_in_as_admin }
  after { log_out }

  describe "POST #create" do
    let(:from_warehouse) { create(:warehouse) }
    let(:to_warehouse) { create(:warehouse) }
    let!(:purchase) { create(:purchase) }
    let!(:purchase_items) { create_list(:purchase_item, 3, purchase:, warehouse: from_warehouse) }

    it "moves the selected purchases and redirects to the index" do
      post :create, params: {selected_items_ids: [purchase.id], destination_id: to_warehouse.id}

      expect(response).to redirect_to(purchases_path)
      expect(purchase_items.map { it.reload.warehouse_id }.uniq).to eq([to_warehouse.id])
    end

    it "redirects back to the purchase show page when purchase_id is provided" do
      post :create, params: {purchase_id: purchase.id, destination_id: to_warehouse.id}

      expect(response).to redirect_to(purchase_path(purchase))
    end
  end
end
