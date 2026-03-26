# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseItems::ShippingCompaniesController, type: :controller do
  include ActionView::RecordIdentifier

  before { sign_in_as_admin }
  after { log_out }

  describe "GET #edit" do
    let(:purchase_item) { create(:purchase_item) }
    let(:shipping_company) { create(:shipping_company) }

    before do
      purchase_item.update!(shipping_company: shipping_company)
    end

    it "returns turbo stream response with edit form" do
      get :edit, params: {purchase_item_id: purchase_item.id}, format: :turbo_stream

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("action=\"replace\" target=\"#{dom_id(purchase_item, :shipping_company)}\"")
      expect(response.body).to include("<turbo-stream")
    end
  end

  describe "GET #show" do
    let(:purchase_item) { create(:purchase_item) }
    let(:shipping_company) { create(:shipping_company) }

    before do
      purchase_item.update!(shipping_company: shipping_company)
    end

    it "returns turbo stream response with show view" do
      get :show, params: {purchase_item_id: purchase_item.id}, format: :turbo_stream

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("action=\"replace\" target=\"#{dom_id(purchase_item, :shipping_company)}\"")
      expect(response.body).to include("<turbo-stream")
    end
  end

  describe "PATCH #update" do
    let(:purchase_item) { create(:purchase_item) }
    let(:shipping_company) { create(:shipping_company, name: "Old Company") }
    let(:new_shipping_company) { create(:shipping_company, name: "New Company") }

    before do
      purchase_item.update!(shipping_company: shipping_company)
    end

    it "updates the purchase_item shipping company" do
      expect {
        patch :update, params: {
          purchase_item_id: purchase_item.id,
          purchase_item: {shipping_company_id: new_shipping_company.id}
        }, format: :turbo_stream
      }.to change { purchase_item.reload.shipping_company }.from(shipping_company).to(new_shipping_company)
    end

    it "allows clearing the shipping company" do
      expect {
        patch :update, params: {
          purchase_item_id: purchase_item.id,
          purchase_item: {shipping_company_id: ""}
        }, format: :turbo_stream
      }.to change { purchase_item.reload.shipping_company }.from(shipping_company).to(nil)
    end
  end
end
