# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Command endpoint authorization" do
  let(:purchase_item) { create(:purchase_item, sale_item: create(:sale_item), shipping_company:, tracking_number: "KEEP", shipping_cost: 3) }
  let(:purchase) { purchase_item.purchase }
  let(:warehouse) { purchase_item.warehouse }
  let(:sale_item) { purchase_item.sale_item }
  let(:sale) { sale_item.sale }
  let(:unlinked_item) { create(:purchase_item, shipping_company:) }
  let(:expense) { create(:purchase_expense, purchase_item:, amount: 4) }
  let(:payment) { create(:payment, purchase:, value: 10) }
  let(:product) { create(:product, :synced) }
  let(:shipping_company) { create(:shipping_company) }

  admin_only = {
    "PATCH /purchase_items/:id" => [
      -> { patch purchase_item_path(purchase_item), params: {purchase_item: {weight: 9}} },
      -> { purchase_item.reload.weight }
    ],
    "DELETE /purchase_items/:id" => [
      -> { delete purchase_item_path(purchase_item) },
      -> { PurchaseItem.exists?(purchase_item.id) }
    ],
    "PATCH /purchase_items/:id/tracking_number" => [
      -> { patch purchase_item_tracking_number_path(purchase_item), params: {purchase_item: {tracking_number: "NEW"}} },
      -> { purchase_item.reload.tracking_number }
    ],
    "PATCH /purchase_items/:id/shipping_company" => [
      -> { patch purchase_item_shipping_company_path(purchase_item), params: {purchase_item: {shipping_company_id: shipping_company.id}} },
      -> { purchase_item.reload.shipping_company_id }
    ],
    "PATCH /purchase_items/:id/shipping_cost" => [
      -> { patch purchase_item_shipping_cost_path(purchase_item), params: {purchase_item: {shipping_cost: 99}} },
      -> { purchase_item.reload.shipping_cost }
    ],
    "PATCH /purchase_items/:id/shipping_details" => [
      -> { patch purchase_item_shipping_details_path(purchase_item), params: {purchase_item: {tracking_number: "NEW", shipping_company_id: shipping_company.id, shipping_cost: 99}} },
      -> { purchase_item.reload.attributes.values_at("tracking_number", "shipping_company_id", "shipping_cost") }
    ],
    "POST /purchase_items/:id/expenses" => [
      -> { post purchase_item_expenses_path(purchase_item), params: {purchase_expense: {description: "Damaged", amount: 4}} },
      -> { PurchaseExpense.count }
    ],
    "PATCH /purchase_items/:id/expenses/:id" => [
      -> { patch purchase_item_expense_path(purchase_item, expense), params: {purchase_expense: {amount: 99}} },
      -> { expense.reload.amount }
    ],
    "DELETE /purchase_items/:id/expenses/:id" => [
      -> { delete purchase_item_expense_path(purchase_item, expense) },
      -> { PurchaseExpense.exists?(expense.id) }
    ],
    "POST /purchase_items/:id/sale_item_link" => [
      -> { post purchase_item_sale_item_link_path(unlinked_item), params: {sale_item_id: sale_item.id} },
      -> { unlinked_item.reload.sale_item_id }
    ],
    "DELETE /purchase_items/:id/sale_item_link" => [
      -> { delete purchase_item_sale_item_link_path(purchase_item) },
      -> { purchase_item.reload.sale_item_id }
    ],
    "POST /purchase_items/move" => [
      -> { post warehouse_move_path, params: {selected_items_ids: [purchase_item.id], destination_id: create(:warehouse).id, warehouse_id: warehouse.id} },
      -> { purchase_item.reload.warehouse_id }
    ],
    "POST /purchases/:id/payments" => [
      -> { post purchase_payments_path(purchase), params: {payment: {value: 10}} },
      -> { Payment.count }
    ],
    "PATCH /purchases/:id/payments/:id" => [
      -> { patch purchase_payment_path(purchase, payment), params: {payment: {value: 99}} },
      -> { payment.reload.value }
    ],
    "DELETE /purchases/:id/payments/:id" => [
      -> { delete purchase_payment_path(purchase, payment) },
      -> { Payment.exists?(payment.id) }
    ],
    "POST /purchases/move" => [
      -> { post move_path, params: {selected_items_ids: [purchase.id], destination_id: create(:warehouse).id} },
      -> { purchase_item.reload.warehouse_id }
    ],
    "POST /warehouses/:id/items" => [
      -> { post warehouse_items_path(warehouse), params: {purchase_item: {warehouse_id: warehouse.id, purchase_id: purchase.id}} },
      -> { purchase_item && PurchaseItem.count }
    ],
    "PATCH /warehouses/:id/change_position" => [
      -> { patch warehouse_position_path(warehouse), params: {position: "2"} },
      -> { warehouse.reload.position }
    ],
    "POST /sales/:id/link_purchase_items" => [
      -> { post sale_purchase_item_link_path(sale) },
      -> { purchase_item.reload.sale_item_id }
    ],
    "DELETE /sales/:id/items/:id" => [
      -> { delete sale_item_path(sale, sale_item) },
      -> { SaleItem.exists?(sale_item.id) }
    ]
  }

  manager_allowed = {
    "POST /products/pull" => [
      -> { post products_pull_path },
      -> { Shopify::PullProductsJob }
    ],
    "POST /products/:id/shopify_pull" => [
      -> { post product_shopify_pull_path(product) },
      -> { Shopify::PullProductJob }
    ],
    "POST /products/:id/shopify_push" => [
      -> { post product_shopify_push_path(product) },
      -> { Shopify::UpdateProductJob }
    ],
    "POST /sales/pull" => [
      -> { post sales_bulk_pull_path },
      -> { Shopify::PullSalesJob }
    ],
    "POST /sales/:id/pull" => [
      -> { post sale_pull_path(create(:sale, :synced)) },
      -> { Shopify::PullSaleJob }
    ]
  }

  def expect_forbidden_redirect
    expect(response).to redirect_to(noop_path)
    expect(flash[:alert]).to start_with("You don't have permission to view the")
  end

  admin_only.each do |name, (request, state)|
    it "denies a manager #{name} and leaves the record untouched", :aggregate_failures do
      before_state = instance_exec(&state)
      sign_in create(:user, :manager)

      instance_exec(&request)

      expect_forbidden_redirect
      expect(instance_exec(&state)).to eq(before_state)
    end

    it "denies a guest #{name}", :aggregate_failures do
      sign_in create(:user)

      instance_exec(&request)

      expect_forbidden_redirect
    end
  end

  manager_allowed.each do |name, (request, job)|
    it "denies a guest #{name} and enqueues nothing", :aggregate_failures do
      jobs = instance_exec(&job)
      allow(jobs).to receive(:perform_later)
      allow(Woo::PullSalesJob).to receive(:set).and_return(Woo::PullSalesJob)
      allow(Woo::PullSalesJob).to receive(:perform_later)
      sign_in create(:user)

      instance_exec(&request)

      expect_forbidden_redirect
      expect(jobs).not_to have_received(:perform_later)
    end
  end

  describe "POST /media/uploads" do
    it "denies a guest and stores no blob", :aggregate_failures do
      sign_in create(:user)

      expect {
        post media_uploads_path, params: {file: Rack::Test::UploadedFile.new(StringIO.new("x"), "image/jpeg", original_filename: "x.jpg")}
      }.not_to change(ActiveStorage::Blob, :count)

      expect_forbidden_redirect
    end
  end

  describe "POST /pull-last-orders" do
    it "denies a guest and enqueues nothing", :aggregate_failures do
      allow(Woo::PullSalesJob).to receive(:perform_later)
      sign_in create(:user)

      post last_orders_pull_path

      expect_forbidden_redirect
      expect(Woo::PullSalesJob).not_to have_received(:perform_later)
    end
  end
end
