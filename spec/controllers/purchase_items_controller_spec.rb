require "rails_helper"

describe PurchaseItemsController do
  include ActionView::RecordIdentifier

  before { sign_in_as_admin }
  after { log_out }

  describe "DELETE #destroy" do
    it "destroys the purchase_item without destroying the associated purchase" do
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

    it "notifies about warehouse change" do
      post :move, params: valid_params

      expect(PurchasedNotifier).to have_received(:new).with(
        purchase_item_ids: purchase_items.map(&:id),
        from_id: from_warehouse.id,
        to_id: to_warehouse.id
      )
      expect(notifier).to have_received(:handle_warehouse_change)
    end
  end

  describe "GET #edit_shipping_company" do
    let(:purchase_item) { create(:purchase_item) }
    let(:shipping_company) { create(:shipping_company) }

    before do
      purchase_item.update!(shipping_company: shipping_company)
    end

    it "returns turbo stream response with edit form" do
      get :edit_shipping_company, params: {id: purchase_item.id}, format: :turbo_stream

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      # Check that the turbo stream targets the correct element using dom_id
      expect(response.body).to include("action=\"replace\" target=\"#{dom_id(purchase_item, :shipping_company)}\"")
      # Check that it's a valid turbo stream response
      expect(response.body).to include("<turbo-stream")
    end

    it "assigns the purchase_item" do
      get :edit_shipping_company, params: {id: purchase_item.id}, format: :turbo_stream

      expect(assigns(:purchase_item)).to eq(purchase_item)
    end
  end

  describe "GET #cancel_edit_shipping_company" do
    let(:purchase_item) { create(:purchase_item) }
    let(:shipping_company) { create(:shipping_company) }

    before do
      purchase_item.update!(shipping_company: shipping_company)
    end

    it "returns turbo stream response with show view" do
      get :cancel_edit_shipping_company, params: {id: purchase_item.id}, format: :turbo_stream

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      # Check that the turbo stream targets the correct element using dom_id
      expect(response.body).to include("action=\"replace\" target=\"#{dom_id(purchase_item, :shipping_company)}\"")
      # Check that it's a valid turbo stream response
      expect(response.body).to include("<turbo-stream")
    end
  end

  describe "PATCH #update_shipping_company" do
    let(:purchase_item) { create(:purchase_item) }
    let(:shipping_company) { create(:shipping_company, name: "Old Company") }
    let(:new_shipping_company) { create(:shipping_company, name: "New Company") }

    before do
      purchase_item.update!(shipping_company: shipping_company)
    end

    context "with valid shipping company" do
      it "updates the purchase_item shipping company" do
        expect {
          patch :update_shipping_company, params: {
            id: purchase_item.id,
            purchase_item: {shipping_company_id: new_shipping_company.id}
          }, format: :turbo_stream
        }.to change { purchase_item.reload.shipping_company }.from(shipping_company).to(new_shipping_company)
      end

      it "returns turbo stream response with show view" do
        patch :update_shipping_company, params: {
          id: purchase_item.id,
          purchase_item: {shipping_company_id: new_shipping_company.id}
        }, format: :turbo_stream

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        # Check that the turbo stream targets the correct element using dom_id
        expect(response.body).to include("action=\"replace\" target=\"#{dom_id(purchase_item, :shipping_company)}\"")
        # Check that it's a valid turbo stream response
        expect(response.body).to include("<turbo-stream")
      end
    end

    context "with invalid shipping company" do
      it "updates to nil when shipping_company_id is nil" do
        expect {
          patch :update_shipping_company, params: {
            id: purchase_item.id,
            purchase_item: {shipping_company_id: ""}
          }, format: :turbo_stream
        }.to change { purchase_item.reload.shipping_company }.from(shipping_company).to(nil)
      end

      it "returns turbo stream response with show view when updated to nil" do
        patch :update_shipping_company, params: {
          id: purchase_item.id,
          purchase_item: {shipping_company_id: ""}
        }, format: :turbo_stream

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        # Check that the turbo stream targets the correct element using dom_id
        expect(response.body).to include("action=\"replace\" target=\"#{dom_id(purchase_item, :shipping_company)}\"")
        # Check that it's a valid turbo stream response
        expect(response.body).to include("<turbo-stream")
      end
    end
  end
end
