# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Purchase item inline updates" do
  before { sign_in_as_admin }

  describe "PATCH /purchase_items/:purchase_item_id/tracking_number" do
    it "updates the tracking number and redirects to the requested return path" do
      warehouse = create(:warehouse)
      shipping_company = create(:shipping_company)
      purchase_item = create(:purchase_item, warehouse: warehouse, shipping_company: shipping_company)

      patch purchase_item_tracking_number_path(purchase_item), params: {
        purchase_item: {tracking_number: "TRACK-99"},
        return_to: warehouse_path(warehouse)
      }

      expect(response).to redirect_to(warehouse_path(warehouse))
      expect(purchase_item.reload.tracking_number).to eq("TRACK-99")
    end

    it "redirects with Inertia errors instead of rendering the old inline partial" do
      warehouse = create(:warehouse)
      purchase_item = create(:purchase_item, warehouse: warehouse)

      patch purchase_item_tracking_number_path(purchase_item), params: {
        purchase_item: {tracking_number: "TRACK-99"},
        return_to: warehouse_path(warehouse)
      }

      expect(response).to redirect_to(warehouse_path(warehouse))

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Warehouses/Show")
      expect(inertia.props[:errors][:shipping_company_id]).to eq("can't be blank")
    end
  end

  describe "PATCH /purchase_items/:purchase_item_id/shipping_company" do
    it "updates the shipping company and redirects to the requested return path" do
      warehouse = create(:warehouse)
      shipping_company = create(:shipping_company)
      purchase_item = create(:purchase_item, warehouse: warehouse)

      patch purchase_item_shipping_company_path(purchase_item), params: {
        purchase_item: {shipping_company_id: shipping_company.id},
        return_to: warehouse_path(warehouse)
      }

      expect(response).to redirect_to(warehouse_path(warehouse))
      expect(purchase_item.reload.shipping_company).to eq(shipping_company)
    end
  end

  describe "PATCH /purchase_items/:purchase_item_id/shipping_cost" do
    it "updates the shipping cost and redirects to the requested return path" do
      warehouse = create(:warehouse)
      purchase_item = create(:purchase_item, warehouse: warehouse, shipping_cost: 5)

      patch purchase_item_shipping_cost_path(purchase_item), params: {
        purchase_item: {shipping_cost: "12"},
        return_to: warehouse_path(warehouse)
      }

      expect(response).to redirect_to(warehouse_path(warehouse))
      expect(purchase_item.reload.shipping_cost).to eq(BigDecimal("12"))
    end
  end
end
