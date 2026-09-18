# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseItems::SaleItemLinksController do
  before { sign_in_as_admin }
  after { log_out }

  describe "POST #create" do
    it "routes replacement through the atomic exact-link command" do
      purchase = create(:purchase)
      sale_item = create(:sale_item, product: purchase.product, variant: purchase.variant)
      existing = create(:purchase_item, purchase:, sale_item:)
      replacement = create(:purchase_item, purchase:)
      allow(PurchaseItem).to receive(:link_exact!)

      post :create, params: {
        purchase_item_id: replacement.id,
        sale_item_id: sale_item.id,
        purchase_item_to_unlink_id: existing.id
      }

      expect(PurchaseItem).to have_received(:link_exact!).with(
        assignments: [{purchase_item: replacement, sale_item:}],
        unlink_purchase_items: [existing]
      )
    end
  end

  describe "DELETE #destroy" do
    let(:sale_item) { create(:sale_item) }
    let(:purchase_item) { create(:purchase_item, sale_item: sale_item) }

    it "unlinks the sale item" do
      allow(PurchaseItem).to receive(:link_exact!).and_call_original

      delete :destroy, params: {purchase_item_id: purchase_item.id}

      expect(purchase_item.reload.sale_item).to be_nil
      expect(PurchaseItem).to have_received(:link_exact!).with(
        assignments: [],
        unlink_purchase_items: [purchase_item]
      )
      expect(response).to redirect_to(sale_item_path(sale_item.sale, sale_item))
      expect(flash[:notice]).to eq("Purchase item was successfully unlinked")
    end
  end
end
