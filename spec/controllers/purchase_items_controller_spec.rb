# frozen_string_literal: true

require "rails_helper"

describe PurchaseItemsController do
  include ActionView::RecordIdentifier

  render_views

  before { sign_in_as_admin }
  after { log_out }

  describe "GET #edit" do
    let(:purchase_item) { create(:purchase_item) }

    it "renders the Inertia edit component with form props" do
      get :edit, params: {id: purchase_item.id}

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect_inertia.to render_component("PurchaseItems/Edit")
        expect(inertia.props[:purchase_item][:id]).to eq(purchase_item.id)
        expect(inertia.props[:purchase_item][:redirect_to_sale_item]).to be false
        expect(inertia.props[:options].keys).to contain_exactly("warehouses", "purchases", "shipping_companies")
        expect(inertia.props[:sale_items_table]).to be_an(Array)
      end
    end

    it "sets redirect_to_sale_item when param is present" do
      get :edit, params: {id: purchase_item.id, redirect_to_sale_item: "1"}

      expect(inertia.props[:purchase_item][:redirect_to_sale_item]).to be true
    end
  end

  describe "GET #show" do
    let(:purchase_item) { create(:purchase_item) }
    let(:media) { create(:media, :for_purchase_item, mediaable: purchase_item) }

    it "renders the Inertia show component with purchase item media" do
      media
      get :show, params: {id: purchase_item.id}

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect_inertia.to render_component("PurchaseItems/Show")
        expect(inertia.props[:purchase_item][:id]).to eq(purchase_item.id)
        expect(inertia.props[:purchase_item][:media].first[:id]).to eq(media.id)
      end
    end
  end

  describe "PATCH #update" do
    it "ignores anonymous direct-expense values" do
      purchase_item = create(:purchase_item, shipping_cost: 5)
      create(:purchase_expense, purchase_item:, amount: 12)

      patch :update, params: {
        id: purchase_item.id,
        purchase_item: {expenses: "999", shipping_cost: "15"}
      }

      purchase_item.reload
      expect(purchase_item.expenses).to eq(BigDecimal("12"))
      expect(purchase_item.shipping_cost).to eq(BigDecimal("15"))
    end

    it "does not accept direct SaleItem assignment" do
      purchase_item = create(:purchase_item)
      sale_item = create(:sale_item, product: purchase_item.purchase.product, variant: purchase_item.purchase.variant)

      patch :update, params: {
        id: purchase_item.id,
        purchase_item: {sale_item_id: sale_item.id, weight: 2}
      }

      expect(purchase_item.reload.sale_item_id).to be_nil
    end
  end

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
end
