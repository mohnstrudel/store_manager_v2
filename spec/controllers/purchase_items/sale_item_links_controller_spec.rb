# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseItems::SaleItemLinksController, type: :controller do
  before { sign_in_as_admin }
  after { log_out }

  describe "DELETE #destroy" do
    let(:sale_item) { create(:sale_item) }
    let(:purchase_item) { create(:purchase_item, sale_item: sale_item) }

    it "unlinks the sale item" do
      delete :destroy, params: {purchase_item_id: purchase_item.id}

      expect(purchase_item.reload.sale_item).to be_nil
      expect(response).to redirect_to(sale_item_path(sale_item.sale, sale_item))
      expect(flash[:notice]).to eq("Purchase item was successfully unlinked")
    end
  end
end
