# frozen_string_literal: true

require "rails_helper"

module Warehouses
  describe DetailsController do
    before { sign_in_as_admin }
    after { log_out }

    describe "GET #show" do
      let(:warehouse) { create(:warehouse) }
      let!(:matching_item) { create(:purchase_item, warehouse:) }
      let!(:other_item) { create(:purchase_item) }

      it "loads the warehouse inventory screen" do
        get :show, params: {id: warehouse.id}

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(assigns(:warehouse)).to eq(warehouse)
          expect(assigns(:purchase_items)).to include(matching_item)
          expect(assigns(:purchase_items)).not_to include(other_item)
        end
      end
    end
  end
end
