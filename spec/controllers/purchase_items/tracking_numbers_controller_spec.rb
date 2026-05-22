# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseItems::TrackingNumbersController, type: :controller do
  include ActionView::RecordIdentifier
  render_views

  before { sign_in_as_admin }
  after { log_out }

  describe "GET #edit" do
    let(:purchase_item) { create(:purchase_item) }

    it "returns the edit form partial" do
      get :edit, params: {purchase_item_id: purchase_item.id}

      expect(response).to be_successful
      expect(response.body).to include("id=\"#{dom_id(purchase_item, :tracking_number)}\"")
    end

    it "assigns the purchase_item" do
      get :edit, params: {purchase_item_id: purchase_item.id}

      expect(assigns(:purchase_item)).to eq(purchase_item)
    end
  end

  describe "GET #show" do
    let(:shipping_company) { create(:shipping_company) }
    let(:purchase_item) { create(:purchase_item, shipping_company:, tracking_number: "ABC123") }

    it "returns the show partial" do
      get :show, params: {purchase_item_id: purchase_item.id}

      expect(response).to be_successful
      expect(response.body).to include("id=\"#{dom_id(purchase_item, :tracking_number)}\"")
    end
  end

  describe "PATCH #update" do
    let(:shipping_company) { create(:shipping_company) }
    let(:purchase_item) { create(:purchase_item, shipping_company:, tracking_number: "OLD") }

    it "updates the tracking number" do
      expect {
        patch :update, params: {
          purchase_item_id: purchase_item.id,
          purchase_item: {tracking_number: "NEW123"}
        }
      }.to change { purchase_item.reload.tracking_number }.from("OLD").to("NEW123")
    end
  end
end
