require "rails_helper"

describe WarehousesController do
  describe "PATCH #update" do
    let(:warehouse) { create(:warehouse) }
    let(:to_warehouse) { create(:warehouse) }
    let(:unused_warehouse) { create(:warehouse) }
    let!(:notification) { create(:notification, name: "Warehouse transition") }

    it "creates warehouse transitions for selected destinations" do
      patch :update, params: {
        id: warehouse.id,
        warehouse: {
          to_warehouse_ids: [to_warehouse.id]
        }
      }

      transition = WarehouseTransition.last
      expect(transition.from_warehouse).to eq(warehouse)
      expect(transition.to_warehouse).to eq(to_warehouse)
      expect(transition.notification).to eq(notification)
    end

    it "removes unused transitions" do
      create(
        :warehouse_transition,
        from_warehouse: warehouse,
        to_warehouse: unused_warehouse
      )

      patch :update, params: {
        id: warehouse.id,
        warehouse: {
          to_warehouse_ids: [to_warehouse.id]
        }
      }

      expect(WarehouseTransition.where(to_warehouse: unused_warehouse)).to be_empty
    end
  end
end
