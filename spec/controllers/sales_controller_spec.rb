require "rails_helper"

RSpec.describe SalesController, type: :controller do
  describe "POST #link_purchased_products" do
    let(:sale) { create(:sale) }
    let(:purchased_product_ids) { [1, 2, 3] }

    before do
      allow(controller).to receive(:set_sale)
      controller.instance_variable_set(:@sale, sale)

      allow(sale).to receive(:link_with_purchased_products).and_return(purchased_product_ids)

      allow(PurchasedNotifier).to receive_message_chain(:new, :handle_product_purchase)
    end

    it "calls link_with_purchased_products on @sale" do
      post :link_purchased_products, params: {id: sale.id}
      expect(sale).to have_received(:link_with_purchased_products)
    end

    it "calls PurchasedNotifier with correct purchased_product_ids" do
      post :link_purchased_products, params: {id: sale.id}
      expect(PurchasedNotifier).to have_received(:new).with(purchased_product_ids:)
      expect(PurchasedNotifier.new(purchased_product_ids:)).to have_received(:handle_product_purchase)
    end

    it "redirects to sale with success notice" do
      post :link_purchased_products, params: {id: sale.id}
      expect(response).to redirect_to(sale)
      expect(flash[:notice]).to eq("Success! Sold products were interlinked with purchased products.")
    end
  end
end
