# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseItems::TrackingNumbersController do
  include ActionView::RecordIdentifier

  render_views

  before { sign_in_as_admin }
  after { log_out }

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
