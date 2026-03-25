# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseItems::WarehouseMovesController, type: :controller do
  before { sign_in_as_admin }
  after { log_out }

  describe "POST #create" do
    let(:from_warehouse) { create(:warehouse) }
    let(:to_warehouse) { create(:warehouse) }
    let(:purchase_items) { create_list(:purchase_item, 3, warehouse: from_warehouse) }

    let(:valid_params) do
      {
        selected_items_ids: purchase_items.map(&:id),
        destination_id: to_warehouse.id,
        warehouse_id: from_warehouse.id
      }
    end

    before { allow(PurchaseItem).to receive(:notify_order_status_change!) }

    it "moves products to destination warehouse" do
      post :create, params: valid_params

      purchase_items.each do |purchase_item|
        expect(purchase_item.reload.warehouse).to eq(to_warehouse)
      end
    end

    it "notifies about warehouse change" do
      post :create, params: valid_params

      expect(PurchaseItem).to have_received(:notify_order_status_change!).with(
        purchase_item_ids: purchase_items.map(&:id),
        from_id: from_warehouse.id,
        to_id: to_warehouse.id
      )
    end
  end
end
