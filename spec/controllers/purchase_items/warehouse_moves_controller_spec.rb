# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseItems::WarehouseMovesController do
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

    it "moves products to destination warehouse" do
      post :create, params: valid_params

      purchase_items.each do |purchase_item|
        expect(purchase_item.reload.warehouse).to eq(to_warehouse)
      end
    end

    it "records a status-changed intent for linked items with an active transition" do
      notification = create(:notification, event_type: :warehouse_changed, status: :active)
      create(:warehouse_transition, notification:, from_warehouse:, to_warehouse:)
      linked_item = create(:purchase_item, warehouse: from_warehouse, sale_item: create(:sale_item))

      post :create, params: valid_params.merge(selected_items_ids: [linked_item.id])

      expect(OutboundEmail.where(purchase_item_id: linked_item.id).pluck(:source, :warehouse_id))
        .to eq([["warehouse_move", to_warehouse.id]])
    end

    it "flashes the destination warehouse link" do
      post :create, params: valid_params

      expect(flash[:notice]).to eq(
        {
          message: "Success! 3 purchased products moved to:",
          link: {
            label: to_warehouse.name,
            href: warehouse_path(to_warehouse)
          }
        }
      )
    end

    it "redirects to the sale when sale_id is given" do
      sale = create(:sale)

      post :create, params: valid_params.merge(sale_id: sale.id)

      expect(response).to redirect_to(sale_path(sale.id))
    end
  end
end
