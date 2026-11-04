# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Purchase item commands" do
  before { sign_in_as_admin }

  describe "GET /purchase_items/:id/edit" do
    it "renders the edit component with form props", :aggregate_failures do
      purchase_item = create(:purchase_item)

      get edit_purchase_item_path(purchase_item)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("PurchaseItems/Edit")
      expect(inertia.props[:purchase_item][:id]).to eq(purchase_item.id)
      expect(inertia.props[:purchase_item][:redirect_to_sale_item]).to be(false)
      expect(inertia.props[:purchase_item][:shipped_at]).to eq("")
      expect(inertia.props[:options].keys).to contain_exactly("warehouses", "purchases", "shipping_companies")
      expect(inertia.props[:sale_items_table]).to be_an(Array)
    end

    it "flags redirect_to_sale_item when the param is present" do
      get edit_purchase_item_path(create(:purchase_item), redirect_to_sale_item: "1")

      expect(inertia.props[:purchase_item][:redirect_to_sale_item]).to be(true)
    end

    it "returns 404 for a purchase item that does not exist" do
      get edit_purchase_item_path(0)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /purchase_items/:id" do
    it "renders the show component with the purchase item media", :aggregate_failures do
      purchase_item = create(:purchase_item)
      media = create(:media, :for_purchase_item, mediaable: purchase_item)

      get purchase_item_path(purchase_item)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("PurchaseItems/Show")
      expect(inertia.props[:purchase_item][:id]).to eq(purchase_item.id)
      expect(inertia.props[:purchase_item][:media].first[:id]).to eq(media.id)
    end

    it "returns 404 for a purchase item that does not exist" do
      get purchase_item_path(0)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /purchase_items/:id" do
    it "ignores anonymous direct-expense values", :aggregate_failures do
      purchase_item = create(:purchase_item, shipping_cost: 5)
      create(:purchase_expense, purchase_item:, amount: 12)

      patch purchase_item_path(purchase_item), params: {purchase_item: {expenses: "999", shipping_cost: "15"}}

      purchase_item.reload
      expect(purchase_item.expenses).to eq(BigDecimal(12))
      expect(purchase_item.shipping_cost).to eq(BigDecimal(15))
    end

    it "does not accept direct SaleItem assignment" do
      purchase_item = create(:purchase_item)
      sale_item = create(:sale_item, product: purchase_item.purchase.product, variant: purchase_item.purchase.variant)

      patch purchase_item_path(purchase_item), params: {purchase_item: {sale_item_id: sale_item.id, weight: 2}}

      expect(purchase_item.reload.sale_item_id).to be_nil
    end

    it "updates the shipped date" do
      purchase_item = create(:purchase_item, tracking_number: "TRK-1", shipping_company: create(:shipping_company))

      patch purchase_item_path(purchase_item), params: {purchase_item: {shipped_at: "2025-12-24"}}

      expect(purchase_item.reload.shipped_at).to eq(Time.zone.local(2025, 12, 24))
    end

    it "returns 404 for a purchase item that does not exist" do
      patch purchase_item_path(0), params: {purchase_item: {weight: 2}}

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /purchase_items/:id" do
    it "destroys the purchase item without destroying its purchase", :aggregate_failures do
      warehouse = create(:warehouse)
      purchase = create(:purchase)
      purchase_item = create_list(:purchase_item, 5, warehouse:, purchase:).first

      expect { delete purchase_item_path(purchase_item) }.to change(PurchaseItem, :count).by(-1)

      expect(PurchaseItem.exists?(purchase_item.id)).to be(false)
      expect(Purchase.exists?(purchase.id)).to be(true)
      expect(response).to redirect_to(warehouse_path(warehouse))
      expect(flash[:notice]).to eq("Purchase item was successfully destroyed")
    end

    it "returns 404 for a purchase item that does not exist" do
      delete purchase_item_path(0)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /purchase_items/:purchase_item_id/shipping_company" do
    let(:shipping_company) { create(:shipping_company, name: "Old Company") }
    let(:purchase_item) { create(:purchase_item, shipping_company:) }

    it "clears the shipping company when the value is blank" do
      expect {
        patch purchase_item_shipping_company_path(purchase_item), params: {purchase_item: {shipping_company_id: ""}}
      }.to change { purchase_item.reload.shipping_company }.from(shipping_company).to(nil)
    end

    it "changes the shipping company" do
      new_company = create(:shipping_company, name: "New Company")

      expect {
        patch purchase_item_shipping_company_path(purchase_item), params: {purchase_item: {shipping_company_id: new_company.id}}
      }.to change { purchase_item.reload.shipping_company }.from(shipping_company).to(new_company)
    end
  end

  describe "POST /purchase_items/:purchase_item_id/expenses" do
    it "creates an item-level named expense", :aggregate_failures do
      item = create(:purchase_item)

      expect {
        post purchase_item_expenses_path(item), params: {purchase_expense: {description: "Damaged packaging", amount: 4.25}}
      }.to change(PurchaseExpense, :count).by(1)

      expect(response).to redirect_to(purchase_path(item.purchase))
      expect(item.reload.expenses).to eq(BigDecimal("4.25"))
    end

    it "redirects invalid expenses to the purchase show page and persists nothing", :aggregate_failures do
      item = create(:purchase_item)

      expect {
        post purchase_item_expenses_path(item), params: {
          purchase_expense: {description: "", amount: 4.25},
          return_to: purchases_path
        }
      }.not_to change(PurchaseExpense, :count)

      expect(response).to redirect_to(purchase_path(item.purchase))
    end

    it "returns 404 for a purchase item that does not exist" do
      post purchase_item_expenses_path(0), params: {purchase_expense: {description: "Damaged packaging", amount: 4.25}}

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /purchase_items/:purchase_item_id/expenses/:id" do
    it "updates an item-level named expense", :aggregate_failures do
      item = create(:purchase_item)
      expense = create(:purchase_expense, purchase_item: item, amount: 4.25)

      patch purchase_item_expense_path(item, expense), params: {purchase_expense: {description: "Repacked", amount: 5}}

      expect(response).to redirect_to(purchase_path(item.purchase))
      expect(expense.reload).to have_attributes(description: "Repacked", amount: BigDecimal(5))
    end

    it "returns 404 and keeps the expense when it belongs to a different item", :aggregate_failures do
      item = create(:purchase_item)
      expense = create(:purchase_expense, purchase_item: item, amount: 4.25)

      patch purchase_item_expense_path(create(:purchase_item), expense), params: {purchase_expense: {amount: 99}}

      expect(response).to have_http_status(:not_found)
      expect(expense.reload.amount).to eq(BigDecimal("4.25"))
    end
  end

  describe "DELETE /purchase_items/:purchase_item_id/expenses/:id" do
    it "destroys the expense and redirects to the purchase", :aggregate_failures do
      item = create(:purchase_item)
      expense = create(:purchase_expense, purchase_item: item, amount: 4.25)

      expect {
        delete purchase_item_expense_path(item, expense)
      }.to change(PurchaseExpense, :count).by(-1)

      expect(response).to redirect_to(purchase_path(item.purchase))
      expect(item.reload.expenses).to eq(0)
    end

    it "returns 404 and keeps the expense when it belongs to a different item", :aggregate_failures do
      expense = create(:purchase_expense, purchase_item: create(:purchase_item))

      expect {
        delete purchase_item_expense_path(create(:purchase_item), expense)
      }.not_to change(PurchaseExpense, :count)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /purchase_items/:purchase_item_id/sale_item_link" do
    it "replaces the existing link with the new purchase item", :aggregate_failures do
      purchase = create(:purchase)
      sale_item = create(:sale_item, product: purchase.product, variant: purchase.variant)
      existing = create(:purchase_item, purchase:, sale_item:)
      replacement = create(:purchase_item, purchase:)

      post purchase_item_sale_item_link_path(replacement), params: {
        sale_item_id: sale_item.id,
        purchase_item_to_unlink_id: existing.id
      }

      expect(response).to redirect_to(edit_purchase_item_path(replacement))
      expect(flash[:notice]).to eq("Sale item linked successfully.")
      expect(replacement.reload.sale_item).to eq(sale_item)
      expect(existing.reload.sale_item).to be_nil
    end

    it "returns 404 for a purchase item that does not exist" do
      post purchase_item_sale_item_link_path(0), params: {sale_item_id: create(:sale_item).id}

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for a sale item that does not exist", :aggregate_failures do
      purchase_item = create(:purchase_item)

      post purchase_item_sale_item_link_path(purchase_item), params: {sale_item_id: 0}

      expect(response).to have_http_status(:not_found)
      expect(purchase_item.reload.sale_item).to be_nil
    end
  end

  describe "DELETE /purchase_items/:purchase_item_id/sale_item_link" do
    it "unlinks the sale item and redirects to it with a notice", :aggregate_failures do
      sale_item = create(:sale_item)
      purchase_item = create(:purchase_item, sale_item:)

      delete purchase_item_sale_item_link_path(purchase_item)

      expect(purchase_item.reload.sale_item).to be_nil
      expect(response).to redirect_to(sale_item_path(sale_item.sale, sale_item))
      expect(flash[:notice]).to eq("Purchase item was successfully unlinked")
    end

    it "returns 404 for a purchase item that does not exist" do
      delete purchase_item_sale_item_link_path(0)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /purchase_items/move" do
    let(:from_warehouse) { create(:warehouse) }
    let(:to_warehouse) { create(:warehouse) }
    let(:params) { {destination_id: to_warehouse.id, warehouse_id: from_warehouse.id} }

    it "moves every selected item to the destination warehouse" do
      purchase_items = create_list(:purchase_item, 3, warehouse: from_warehouse)

      post warehouse_move_path, params: params.merge(selected_items_ids: purchase_items.map(&:id))

      expect(purchase_items.map { it.reload.warehouse }).to all(eq(to_warehouse))
    end

    it "records a status-changed intent for linked items with an active transition" do
      notification = create(:notification, event_type: :warehouse_changed, status: :active)
      create(:warehouse_transition, notification:, from_warehouse:, to_warehouse:)
      linked_item = create(:purchase_item, warehouse: from_warehouse, sale_item: create(:sale_item))

      post warehouse_move_path, params: params.merge(selected_items_ids: [linked_item.id])

      expect(OutboundEmail.where(purchase_item_id: linked_item.id).pluck(:source, :warehouse_id))
        .to eq([["warehouse_move", to_warehouse.id]])
    end

    it "redirects to the sale when sale_id is given" do
      sale = create(:sale)
      purchase_item = create(:purchase_item, warehouse: from_warehouse)

      post warehouse_move_path, params: params.merge(selected_items_ids: [purchase_item.id], sale_id: sale.id)

      expect(response).to redirect_to(sale_path(sale.id))
    end

    it "returns 422 and moves nothing when the destination warehouse does not exist", :aggregate_failures do
      purchase_item = create(:purchase_item, warehouse: from_warehouse)

      post warehouse_move_path, params: {selected_items_ids: [purchase_item.id], destination_id: 0}

      expect(response).to have_http_status(:unprocessable_content)
      expect(purchase_item.reload.warehouse).to eq(from_warehouse)
    end
  end

  describe "warehouse items" do
    let(:warehouse) { create(:warehouse) }
    let(:purchase) { create(:purchase) }

    it "renders the new component with warehouse-scoped form props", :aggregate_failures do
      get new_warehouse_item_path(warehouse)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("PurchaseItems/New")
      expect(inertia.props[:purchase_item][:warehouse_id]).to eq(warehouse.id)
      expect(inertia.props[:form_action]).to end_with("/warehouses/#{warehouse.id}/items")
      expect(inertia.props[:cancel_path]).to end_with("/warehouses/#{warehouse.id}")
    end

    it "creates a purchase item without direct expenses and redirects to the warehouse", :aggregate_failures do
      expect {
        post warehouse_items_path(warehouse), params: {
          purchase_item: {
            warehouse_id: warehouse.id, purchase_id: purchase.id,
            weight: 1, length: 1, width: 1, height: 1,
            expenses: "9.99", shipping_cost: "9.99"
          }
        }
      }.to change(PurchaseItem, :count).by(1)

      expect(response).to redirect_to(warehouse_path(warehouse))
      expect(PurchaseItem.last.expenses).to eq(BigDecimal(0))
    end

    it "does not accept direct SaleItem assignment" do
      sale_item = create(:sale_item, product: purchase.product, variant: purchase.variant)

      post warehouse_items_path(warehouse), params: {
        purchase_item: {warehouse_id: warehouse.id, purchase_id: purchase.id, sale_item_id: sale_item.id}
      }

      expect(PurchaseItem.last.sale_item_id).to be_nil
    end

    it "returns 404 for a warehouse that does not exist" do
      post warehouse_items_path(0), params: {purchase_item: {purchase_id: purchase.id}}

      expect(response).to have_http_status(:not_found)
    end
  end
end
