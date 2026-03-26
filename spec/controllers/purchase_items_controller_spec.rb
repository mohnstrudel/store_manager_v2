# frozen_string_literal: true

require "rails_helper"

describe PurchaseItemsController do
  include ActionView::RecordIdentifier

  render_views

  before { sign_in_as_admin }
  after { log_out }

  describe "GET #show" do
    let(:purchase_item) { create(:purchase_item) }
    let(:media) { create(:media, :for_purchase_item, mediaable: purchase_item) }

    it "renders the shared gallery for purchase item media" do
      media
      get :show, params: {id: purchase_item.id}

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('data-controller="gallery"')
        expect(response.body).to include('data-gallery-target="main"')
      end
    end
  end

  describe "DELETE #destroy" do
    # rubocop:todo RSpec/MultipleExpectations
    it "destroys the purchase_item without destroying the associated purchase" do
      # rubocop:enable RSpec/MultipleExpectations
      warehouse = create(:warehouse)
      purchase = create(:purchase)
      purchase_item = create_list(:purchase_item, 5, warehouse: warehouse, purchase: purchase).first

      expect {
        delete :destroy, params: {id: purchase_item.id}
      }.to change(PurchaseItem, :count).by(-1)

      expect(PurchaseItem.exists?(purchase_item.id)).to be false
      expect(Purchase.exists?(purchase.id)).to be true
      expect(response).to redirect_to(warehouse_path(warehouse))
      expect(flash[:notice]).to eq("Purchase item was successfully destroyed")
    end
  end
end
