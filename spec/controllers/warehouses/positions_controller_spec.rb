# frozen_string_literal: true

require "rails_helper"

RSpec.describe Warehouses::PositionsController, type: :controller do
  before { sign_in_as_admin }
  after { log_out }

  describe "PATCH #update" do
    let(:warehouse) { create(:warehouse, position: 1) }
    let!(:other_warehouse) { create(:warehouse, position: 2) }

    it "updates the warehouse position" do
      patch :update, params: {warehouse_id: warehouse.id, position: 2}

      expect(response).to redirect_to(warehouses_url)
      expect(response).to have_http_status(:see_other)
      expect(warehouse.reload.position).to eq(2)
    end

    it "rejects non-positive positions" do
      patch :update, params: {warehouse_id: warehouse.id, position: 0}

      expect(response).to have_http_status(:bad_request)
      expect(warehouse.reload.position).to eq(1)
    end
  end
end
