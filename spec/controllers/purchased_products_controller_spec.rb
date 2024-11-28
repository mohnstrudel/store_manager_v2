require "rails_helper"

describe PurchasedProductsController do
  describe "DELETE #destroy" do
    it "destroys the purchased_product without destroying the associated purchase" do
      warehouse = create(:warehouse)
      purchase = create(:purchase)
      purchased_product = create_list(:purchased_product, 5, warehouse: warehouse, purchase: purchase).first

      warn PurchasedProduct.find(purchased_product.id).inspect

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
    let(:notification_service) {
      class_spy(Notification).tap do |spy|
        allow(spy).to receive(:event_types).and_return({warehouse_changed: 1})
      end
    }

    let(:valid_params) do
      {
        selected_items_ids: purchased_products.map(&:id),
        destination_id: to_warehouse.id,
        warehouse_id: from_warehouse.id
      }
    end

    before do
      stub_const("Notification", notification_service)
    end

    it "moves products to destination warehouse" do
      post :move, params: valid_params

      purchased_products.each do |purchased_product|
        expect(purchased_product.reload.warehouse).to eq(to_warehouse)
      end
    end

    it "dispatches notifications for each moved product" do
      post :move, params: valid_params

      expect(notification_service).to have_received(:dispatch).with(
        event: Notification.event_types[:warehouse_changed],
        context: {
          purchased_product_ids: purchased_products.map(&:id),
          from_id: from_warehouse.id,
          to_id: to_warehouse.id.to_s
        }
      ).exactly(1).times
    end
  end
end
