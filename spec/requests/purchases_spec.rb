# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Purchases" do
  before { sign_in_as_admin }

  describe "GET /purchases" do
    it "renders the index Inertia component with pagination and search" do
      purchase = create(:purchase, order_reference: "PO-BOOK-1")
      create(:purchase, order_reference: "OTHER")

      get purchases_path, params: {q: "PO-BOOK"}

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Purchases/Index")
      expect_inertia.to have_props(
        pagination: {current_page: 1, total_pages: 1, total_count: 1, limit: 50},
        search: {q: "PO-BOOK"}
      )

      purchases = inertia.props[:purchases]
      expect(purchases.map { |item| item[:id] }).to eq([purchase.id])
      expect(purchases.first[:order_reference]).to eq("PO-BOOK-1")
    end
  end

  describe "GET /purchases/:id" do
    it "renders the show Inertia component with items and payments" do
      warehouse = create(:warehouse, name: "Main Stock")
      purchase = create(:purchase)
      purchase_item = create(:purchase_item, purchase:, warehouse:)
      payment = create(:payment, purchase:, value: 12)

      get purchase_path(purchase)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Purchases/Show")

      purchase_props = inertia.props[:purchase]
      expect(purchase_props[:id]).to eq(purchase.id)
      expect(inertia.props[:purchase_items].first[:id]).to eq(purchase_item.id)
      expect(inertia.props[:purchase_items].first[:warehouse_name]).to eq("Main Stock")
      expect(inertia.props[:payments].first[:id]).to eq(payment.id)
    end
  end
end
