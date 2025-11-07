require "rails_helper"

describe PurchaseItemsController do
  before { sign_in_as_admin }
  after { log_out }

  describe "DELETE #destroy" do
    # rubocop:todo RSpec/MultipleExpectations
    it "destroys the purchase_item without destroying the associated purchase" do
      # rubocop:enable RSpec/MultipleExpectations
      warehouse = create(:warehouse)
      purchase = create(:purchase)
      purchase_item = create_list(:purchase_item, 5, warehouse: warehouse, purchase: purchase).first

      expect {
        delete :destroy, params: {id: purchase_item.id}
      }.to change(PurchaseItem, :count).by(-1)

      expect(PurchaseItem.exists?(purchase_item.id)).to be false
      expect(Purchase.exists?(purchase.id)).to be true
      expect(response).to redirect_to(warehouse_path(warehouse))
      expect(flash[:notice]).to eq("Purchase item was successfully destroyed")
    end
  end

  describe "POST #move" do
    let(:from_warehouse) { create(:warehouse) }
    let(:to_warehouse) { create(:warehouse) }
    let(:purchase_items) { create_list(:purchase_item, 3, warehouse: from_warehouse) }

    let(:notifier) { instance_double(PurchasedNotifier, handle_warehouse_change: true) }

    let(:valid_params) do
      {
        selected_items_ids: purchase_items.map(&:id),
        destination_id: to_warehouse.id,
        warehouse_id: from_warehouse.id
      }
    end

    before do
      allow(PurchasedNotifier).to receive(:new).and_return(notifier)
    end

    it "moves products to destination warehouse" do
      post :move, params: valid_params

      purchase_items.each do |purchase_item|
        expect(purchase_item.reload.warehouse).to eq(to_warehouse)
      end
    end

    it "notifies about warehouse change" do # rubocop:todo RSpec/MultipleExpectations
      post :move, params: valid_params

      expect(PurchasedNotifier).to have_received(:new).with(
        purchase_item_ids: purchase_items.map(&:id),
        from_id: from_warehouse.id,
        to_id: to_warehouse.id
      )
      expect(notifier).to have_received(:handle_warehouse_change)
    end
  end
end
