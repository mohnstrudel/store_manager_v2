# frozen_string_literal: true

require "rails_helper"

# rubocop:disable RSpec/MultipleExpectations
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
      expect(purchases.pluck(:id)).to eq([purchase.id])
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

  describe "GET /purchases/new" do
    it "renders the new Inertia component with form options and a preselected product" do
      product = create(:product)
      variant = create(:variant, product:)
      supplier = create(:supplier)
      warehouse = create(:warehouse, is_default: true)

      get new_purchase_path(product:)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Purchases/New")
      expect(inertia.props[:purchase]).to include(
        id: nil,
        path: "",
        product_id: product.id,
        variant_id: nil,
        supplier_id: nil,
        order_reference: "",
        item_price: "",
        amount: "",
        warehouse_id: warehouse.id,
        payment_value: ""
      )
      expect(inertia.props[:purchase][:variant_options]).to include(
        include(value: variant.id, label: variant.title)
      )
      expect(inertia.props[:options]).to include(product_variants_path: product_variants_path)
      expect(inertia.props[:options][:products].pluck(:value)).to include(product.id)
      expect(inertia.props[:options][:suppliers].pluck(:value)).to include(supplier.id)
      expect(inertia.props[:options][:warehouses].pluck(:value)).to include(warehouse.id)
    end
  end

  describe "GET /purchases/:id/edit" do
    it "renders the edit Inertia component with form options" do
      product = create(:product)
      variant = create(:variant, product:)
      purchase = create(:purchase, product:, variant:)
      warehouse = create(:warehouse, is_default: true)

      get edit_purchase_path(purchase)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Purchases/Edit")
      expect(inertia.props[:purchase]).to include(
        id: purchase.id,
        path: purchase_path(purchase),
        product_id: product.id,
        variant_id: variant.id,
        supplier_id: purchase.supplier_id,
        order_reference: purchase.order_reference,
        item_price: purchase.item_price.to_s,
        amount: purchase.amount.to_s,
        warehouse_id: warehouse.id,
        payment_value: ""
      )
      expect(inertia.props[:purchase][:variant_options]).to include(
        include(value: variant.id, label: variant.title)
      )
      expect(inertia.props[:options][:product_variants_path]).to eq(product_variants_path)
    end
  end

  describe "POST /purchases" do
    it "creates a purchase with initial warehouse and payment", :aggregate_failures do
      product = create(:product)
      supplier = create(:supplier)
      warehouse = create(:warehouse, is_default: true)

      expect {
        post purchases_path, params: {
          purchase: {
            supplier_id: supplier.id,
            product_id: product.id,
            item_price: "15.00",
            amount: "2",
            order_reference: "PO-1",
            warehouse_id: warehouse.id
          },
          initial_payment: {
            value: "30.00"
          }
        }
      }.to change(Purchase, :count).by(1)
        .and change(PurchaseItem, :count).by(2)
        .and change(Payment, :count).by(1)

      purchase = Purchase.order(:id).last
      expect(response).to redirect_to(purchase_path(purchase))
      expect(purchase.purchase_items.pluck(:warehouse_id).uniq).to eq([warehouse.id])
      expect(purchase.payments.first.value).to eq(BigDecimal(30))
    end

    it "redirects to the new page with errors when invalid" do
      post purchases_path, params: {
        purchase: {
          supplier_id: "",
          product_id: "",
          item_price: "",
          amount: ""
        }
      }

      expect(response).to redirect_to(new_purchase_path)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Purchases/New")
      expect(inertia.props[:errors]).to include(
        supplier_id: "Supplier can't be blank",
        item_price: "Item price can't be blank",
        amount: "Amount can't be blank"
      )
    end
  end

  describe "PATCH /purchases/:id" do
    it "accepts submitting the edit form without changes", :aggregate_failures do
      product = create(:product)
      supplier = create(:supplier)
      purchase = create(
        :purchase,
        product:,
        supplier:,
        item_price: BigDecimal(15),
        amount: 2,
        order_reference: "PO-1"
      )

      patch purchase_path(purchase), params: {
        purchase: {
          supplier_id: supplier.id,
          product_id: product.id,
          variant_id: "",
          item_price: "15.00",
          amount: "2",
          order_reference: "PO-1"
        }
      }

      expect(response).to redirect_to(purchase_path(purchase.reload))
      expect(purchase.amount).to eq(2)
      expect(purchase.item_price).to eq(BigDecimal(15))
    end

    it "redirects to the edit page with errors when invalid" do
      purchase = create(:purchase)

      patch purchase_path(purchase), params: {
        purchase: {
          supplier_id: "",
          product_id: purchase.product_id,
          item_price: "",
          amount: ""
        }
      }

      expect(response).to be_redirect
      expect(response.location).to match(%r{/purchases/.+/edit\z})

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Purchases/Edit")
      expect(inertia.props[:errors]).to include(
        supplier_id: "Supplier can't be blank",
        item_price: "Item price can't be blank",
        amount: "Amount can't be blank"
      )
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations
