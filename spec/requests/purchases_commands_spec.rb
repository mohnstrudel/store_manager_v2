# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Purchase commands" do
  before { sign_in_as_admin }

  describe "GET /purchases/:id" do
    it "renders a purchase whose product association is missing", :aggregate_failures do
      purchase = create(:purchase)
      purchase.update_columns(product_id: nil) # rubocop:disable Rails/SkipsModelValidations

      get purchase_path(purchase)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Purchases/Show")
    end

    it "returns 404 for a purchase that does not exist" do
      get purchase_path(0)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /purchases" do
    let(:supplier) { create(:supplier) }
    let(:product) { create(:product) }
    let(:warehouse) { create(:warehouse) }

    it "creates the purchase with its items in the warehouse and the initial payment", :aggregate_failures do
      expect {
        post purchases_path, params: {
          purchase: {supplier_id: supplier.id, product_id: product.id, amount: 2, item_price: "10.00", warehouse_id: warehouse.id},
          initial_payment: {value: "20.00"}
        }
      }.to change(Purchase, :count).by(1)

      purchase = Purchase.last
      expect(response).to redirect_to(purchase_path(purchase))
      expect(purchase.purchase_items.pluck(:warehouse_id).uniq).to eq([warehouse.id])
      expect(purchase.payments.pluck(:value)).to eq([BigDecimal(20)])
    end

    it "rejects a purchase without a product and persists no payment", :aggregate_failures do
      purchase_count = Purchase.count
      payment_count = Payment.count

      post purchases_path, params: {
        purchase: {product_id: "", supplier_id: supplier.id, amount: 2, item_price: "10.00", warehouse_id: warehouse.id},
        initial_payment: {value: "20.00"}
      }

      expect([Purchase.count, Payment.count]).to eq([purchase_count, payment_count])
      expect(response).to redirect_to(new_purchase_path)
    end
  end

  describe "PATCH /purchases/:id" do
    let(:purchase) { create(:purchase) }

    def purchase_params(**overrides)
      {
        supplier_id: purchase.supplier_id,
        product_id: purchase.product_id,
        variant_id: purchase.variant_id,
        amount: 3,
        item_price: purchase.item_price,
        **overrides
      }
    end

    it "updates the purchase and redirects to it", :aggregate_failures do
      patch purchase_path(purchase), params: {purchase: purchase_params(order_reference: "UPDATED-REF")}

      expect(response).to redirect_to(purchase_path(purchase.reload))
      expect(purchase.order_reference).to eq("UPDATED-REF")
    end

    it "redirects to the edit page and leaves the purchase unchanged on an invalid update", :aggregate_failures do
      original_reference = purchase.order_reference

      patch purchase_path(purchase), params: {purchase: purchase_params(supplier_id: "", order_reference: "SHOULD-NOT-SAVE")}

      expect(response).to redirect_to(edit_purchase_path(purchase))
      expect(purchase.reload.order_reference).to eq(original_reference)
    end

    it "returns 404 for a purchase that does not exist" do
      patch purchase_path(0), params: {purchase: purchase_params}

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /purchases/:purchase_id/payments" do
    let(:purchase) { create(:purchase) }

    it "creates a payment and redirects to the purchase", :aggregate_failures do
      payment_date = Date.new(2026, 3, 30)

      expect {
        post purchase_payments_path(purchase), params: {payment: {value: 10, payment_date:}}
      }.to change(Payment, :count).by(1)

      expect(response).to redirect_to(purchase_path(purchase))
      expect(Payment.last).to have_attributes(purchase_id: purchase.id, payment_date: payment_date.in_time_zone)
    end

    it "persists nothing and redirects to the purchase when invalid", :aggregate_failures do
      expect {
        post purchase_payments_path(purchase), params: {payment: {value: nil}, return_to: purchases_path}
      }.not_to change(Payment, :count)

      expect(response).to redirect_to(purchase_path(purchase))
    end

    it "returns 404 for a purchase that does not exist" do
      post purchase_payments_path(0), params: {payment: {value: 10}}

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /purchases/:purchase_id/payments/:id" do
    it "updates the payment and redirects to the purchase", :aggregate_failures do
      purchase = create(:purchase)
      payment = create(:payment, purchase:, value: 10)
      payment_date = Date.new(2026, 4, 1)

      patch purchase_payment_path(purchase, payment), params: {payment: {value: 25, payment_date:}}

      expect(response).to redirect_to(purchase_path(purchase))
      expect(payment.reload.value).to eq(BigDecimal(25))
      expect(payment.payment_date.to_date).to eq(payment_date)
    end

    it "returns 404 and keeps the payment when it belongs to another purchase", :aggregate_failures do
      payment = create(:payment, purchase: create(:purchase), value: 10)

      patch purchase_payment_path(create(:purchase), payment), params: {payment: {value: 25}}

      expect(response).to have_http_status(:not_found)
      expect(payment.reload.value).to eq(BigDecimal(10))
    end
  end

  describe "DELETE /purchases/:purchase_id/payments/:id" do
    it "removes the payment and redirects to the purchase", :aggregate_failures do
      purchase = create(:purchase)
      payment = create(:payment, purchase:)

      expect {
        delete purchase_payment_path(purchase, payment)
      }.to change(Payment, :count).by(-1)

      expect(response).to redirect_to(purchase_path(purchase))
    end

    it "returns 404 and keeps the payment when it belongs to another purchase", :aggregate_failures do
      payment = create(:payment, purchase: create(:purchase))

      expect {
        delete purchase_payment_path(create(:purchase), payment)
      }.not_to change(Payment, :count)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /purchases/move" do
    let(:from_warehouse) { create(:warehouse) }
    let(:to_warehouse) { create(:warehouse) }
    let!(:purchase) { create(:purchase) }
    let!(:purchase_items) { create_list(:purchase_item, 3, purchase:, warehouse: from_warehouse) }

    it "moves the items of the given purchase and redirects back to it", :aggregate_failures do
      post move_path, params: {purchase_id: purchase.id, destination_id: to_warehouse.id}

      expect(response).to redirect_to(purchase_path(purchase))
      expect(purchase_items.map { it.reload.warehouse_id }.uniq).to eq([to_warehouse.id])
    end

    it "returns 422 and moves nothing when the destination warehouse does not exist", :aggregate_failures do
      post move_path, params: {selected_items_ids: [purchase.id], destination_id: 0}

      expect(response).to have_http_status(:unprocessable_content)
      expect(purchase_items.map { it.reload.warehouse_id }.uniq).to eq([from_warehouse.id])
    end
  end
end
