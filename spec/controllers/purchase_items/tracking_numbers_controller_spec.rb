# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseItems::TrackingNumbersController, type: :controller do
  include ActionView::RecordIdentifier

  before { sign_in_as_admin }
  after { log_out }

  describe "GET #edit" do
    let(:purchase_item) { create(:purchase_item) }

    it "returns turbo stream response with edit form" do
      get :edit, params: {purchase_item_id: purchase_item.id}, format: :turbo_stream

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("action=\"replace\" target=\"#{dom_id(purchase_item, :tracking_number)}\"")
      expect(response.body).to include("<turbo-stream")
    end

    it "assigns the purchase_item" do
      get :edit, params: {purchase_item_id: purchase_item.id}, format: :turbo_stream

      expect(assigns(:purchase_item)).to eq(purchase_item)
    end
  end

  describe "GET #show" do
    let(:shipping_company) { create(:shipping_company) }
    let(:purchase_item) { create(:purchase_item, shipping_company:, tracking_number: "ABC123") }

    it "returns turbo stream response with show view" do
      get :show, params: {purchase_item_id: purchase_item.id}, format: :turbo_stream

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("action=\"replace\" target=\"#{dom_id(purchase_item, :tracking_number)}\"")
      expect(response.body).to include("<turbo-stream")
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
        }, format: :turbo_stream
      }.to change { purchase_item.reload.tracking_number }.from("OLD").to("NEW123")
    end
  end
end
