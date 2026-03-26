# frozen_string_literal: true

require "rails_helper"

describe WarehousesController do
  before { sign_in_as_admin }
  after { log_out }

  describe "POST #create" do
    # rubocop:disable RSpec/MultipleExpectations
    it "creates the warehouse through the model workflow" do
      expect {
        post :create, params: {
          warehouse: {
            name: "New Warehouse"
          }
        }
      }.to change(Warehouse, :count).by(1)

      aggregate_failures do
        expect(response).to redirect_to(Warehouse.last)
        expect(Warehouse.last.name).to eq("New Warehouse")
      end
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe "PATCH #update" do
    let(:warehouse) { create(:warehouse) }
    let(:to_warehouse) { create(:warehouse) }
    let(:unused_warehouse) { create(:warehouse) }
    let!(:notification) { create(:notification, name: "Warehouse transition") }

    it "creates warehouse transitions for selected destinations" do # rubocop:todo RSpec/MultipleExpectations
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

    it "re-renders the form when another default warehouse already exists" do
      create(:warehouse, :default, name: "Default Warehouse")

      patch :update, params: {
        id: warehouse.id,
        warehouse: {
          is_default: "1"
        }
      }

      aggregate_failures do
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:edit)
        expect(assigns(:positions_count)).to eq(Warehouse.count)
        expect(warehouse.reload.is_default).to be(false)
      end
    end
  end

  describe "DELETE #destroy" do
    it "redirects back with an error when warehouse still has purchase items" do
      warehouse = create(:warehouse)
      create(:purchase_item, warehouse:)

      delete :destroy, params: {id: warehouse.id}

      aggregate_failures do
        expect(response).to redirect_to(warehouse)
        expect(flash[:error]).to include("move out all purchased products")
      end
    end
  end
end
