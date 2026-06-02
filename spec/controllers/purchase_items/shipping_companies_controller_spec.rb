# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseItems::ShippingCompaniesController, type: :controller do
  include ActionView::RecordIdentifier
  render_views

  before { sign_in_as_admin }
  after { log_out }

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
