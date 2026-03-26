# frozen_string_literal: true

require "rails_helper"

module Warehouses
  describe DetailsController do
    render_views

    before { sign_in_as_admin }
    after { log_out }

    describe "GET #show" do
      let(:warehouse) { create(:warehouse) }
      let!(:matching_item) { create(:purchase_item, warehouse:) }
      let!(:other_item) { create(:purchase_item) }
      let(:media) { create(:media, :for_warehouse, mediaable: warehouse) }

      it "loads the warehouse inventory screen" do
        media
        get :show, params: {id: warehouse.id}

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(assigns(:warehouse)).to eq(warehouse)
          expect(assigns(:purchase_items)).to include(matching_item)
          expect(assigns(:purchase_items)).not_to include(other_item)
          expect(response.body).to include('data-controller="gallery"')
          expect(response.body).to include('data-gallery-target="main"')
        end
      end
    end
  end
end
