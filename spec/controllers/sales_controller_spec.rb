require "rails_helper"

RSpec.describe SalesController, type: :controller do
  describe "POST #link_purchase_items" do
    let(:sale) { create(:sale) }
    let(:purchase_item_ids) { [1, 2, 3] }

    before do
      allow(controller).to receive(:set_sale)
      controller.instance_variable_set(:@sale, sale)

      allow(sale).to receive(:link_with_purchase_items).and_return(purchase_item_ids)

      allow(PurchasedNotifier).to receive_message_chain(:new, :handle_product_purchase)
    end

    it "calls link_with_purchase_items on @sale" do
      post :link_purchase_items, params: {id: sale.id}
      expect(sale).to have_received(:link_with_purchase_items)
    end

    it "calls PurchasedNotifier with correct purchase_item_ids" do
      post :link_purchase_items, params: {id: sale.id}
      expect(PurchasedNotifier).to have_received(:new).with(purchase_item_ids:)
      expect(PurchasedNotifier.new(purchase_item_ids:)).to have_received(:handle_product_purchase)
    end

    it "redirects to sale with success notice" do
      post :link_purchase_items, params: {id: sale.id}
      expect(response).to redirect_to(sale)
      expect(flash[:notice]).to eq("Success! Sold products were interlinked with purchased products.")
    end
  end
end
