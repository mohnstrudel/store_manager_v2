require "rails_helper"

describe PurchasedProductsController do
  describe "DELETE #destroy" do
    it "destroys the purchased_product without destroying the associated purchase" do
      warehouse = create(:warehouse)
      purchase = create(:purchase)
      purchased_product = create_list(:purchased_product, 5, warehouse: warehouse, purchase: purchase).first

      expect {
        delete :destroy, params: {id: purchased_product.id}
      }.to change(PurchasedProduct, :count).by(-1)

      expect(PurchasedProduct.exists?(purchased_product.id)).to be false
      expect(Purchase.exists?(purchase.id)).to be true
      expect(response).to redirect_to(warehouse_path(warehouse))
      expect(flash[:notice]).to eq("Purchased product was successfully destroyed.")
    end
  end

  describe "POST #move" do
    let(:from_warehouse) { create(:warehouse) }
    let(:to_warehouse) { create(:warehouse) }
    let(:purchased_products) { create_list(:purchased_product, 3, warehouse: from_warehouse) }

    let(:notifier) { instance_double(Notifier, handle_warehouse_change: true) }

    let(:valid_params) do
      {
        selected_items_ids: purchased_products.map(&:id),
        destination_id: to_warehouse.id,
        warehouse_id: from_warehouse.id
      }
    end

    before do
      allow(Notifier).to receive(:new).and_return(notifier)
    end

    it "moves products to destination warehouse" do
      post :move, params: valid_params

      purchased_products.each do |purchased_product|
        expect(purchased_product.reload.warehouse).to eq(to_warehouse)
      end
    end

    it "notifies about warehouse change" do
      post :move, params: valid_params

      expect(Notifier).to have_received(:new).with(
        purchased_product_ids: purchased_products.map(&:id),
        from_id: from_warehouse.id,
        to_id: to_warehouse.id
      )
      expect(notifier).to have_received(:handle_warehouse_change)
    end
  end
end
