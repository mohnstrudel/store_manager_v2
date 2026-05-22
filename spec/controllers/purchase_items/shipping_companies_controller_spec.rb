# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseItems::ShippingCompaniesController, type: :controller do
  include ActionView::RecordIdentifier
  render_views

  before { sign_in_as_admin }
  after { log_out }

  describe "GET #edit" do
    let(:purchase_item) { create(:purchase_item) }
    let(:shipping_company) { create(:shipping_company) }

    before do
      purchase_item.update!(shipping_company: shipping_company)
    end

    it "returns the edit form partial" do
      get :edit, params: {purchase_item_id: purchase_item.id}

      expect(response).to be_successful
      expect(response.body).to include("id=\"#{dom_id(purchase_item, :shipping_company)}\"")
    end
  end

  describe "GET #show" do
    let(:purchase_item) { create(:purchase_item) }
    let(:shipping_company) { create(:shipping_company) }

    before do
      purchase_item.update!(shipping_company: shipping_company)
    end

    it "returns the show partial" do
      get :show, params: {purchase_item_id: purchase_item.id}

      expect(response).to be_successful
      expect(response.body).to include("id=\"#{dom_id(purchase_item, :shipping_company)}\"")
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
        }
      }.to change { purchase_item.reload.shipping_company }.from(shipping_company).to(new_shipping_company)
    end

    it "allows clearing the shipping company" do
      expect {
        patch :update, params: {
          purchase_item_id: purchase_item.id,
          purchase_item: {shipping_company_id: ""}
        }
      }.to change { purchase_item.reload.shipping_company }.from(shipping_company).to(nil)
    end
  end
end
