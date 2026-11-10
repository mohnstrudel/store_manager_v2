# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sales commands" do
  before { sign_in_as_admin }

  describe "GET /sales" do
    it "finds a sale by its exact store id" do
      matching_sale = create(:sale, woo_store_id: "18159")
      create(:sale, woo_store_id: "99999")

      get sales_path, params: {q: "18159"}

      expect(response).to have_http_status(:ok)
      expect(inertia.props[:sales].pluck(:id)).to eq([matching_sale.id])
    end
  end

  describe "GET /sales/:id" do
    it "finds the sale by its friendly id", :aggregate_failures do
      sale = create(:sale)

      get sale_path(sale.friendly_id)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Sales/Show")
      expect(inertia.props[:sale][:id]).to eq(sale.id)
    end

    it "returns 404 for a sale that does not exist" do
      get sale_path("non-existent")

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /sales" do
    it "creates the sale with its items and redirects with a notice", :aggregate_failures do
      product = create(:product)

      expect {
        post sales_path, params: {
          sale: {
            customer_id: create(:customer).id,
            total: 100,
            status: "processing",
            shipping_address: {address_1: "123 Test St", city: "Test City", country: "US", postcode: "12345"}
          },
          sale_items: {"0" => {product_id: product.id, qty: "1", price: "100.00"}}
        }
      }.to change(Sale, :count).by(1)

      sale = Sale.last
      expect(response).to redirect_to(sale_path(sale))
      expect(flash[:notice]).to eq("Sale was successfully created")
      expect(sale.sale_items.sole.product).to eq(product)
    end
  end

  describe "PATCH /sales/:id" do
    it "updates the status and sale items and redirects with a notice", :aggregate_failures do
      sale = create(:sale, status: "processing")
      sale_item = create(:sale_item, sale:, qty: 1, price: 100)

      patch sale_path(sale), params: {
        sale: {status: "completed"},
        sale_items: {"0" => {id: sale_item.id, product_id: sale_item.product_id, qty: "3", price: "150"}}
      }

      expect(response).to redirect_to(sale_path(sale))
      expect(flash[:notice]).to eq("Sale was successfully updated")
      expect(sale.reload.status).to eq("completed")
      expect(sale_item.reload).to have_attributes(qty: 3, price: BigDecimal(150))
    end
  end

  describe "DELETE /sales/:id" do
    it "destroys the sale and redirects to the list", :aggregate_failures do
      sale = create(:sale)

      expect { delete sale_path(sale) }.to change(Sale, :count).by(-1)

      expect(response).to redirect_to(sales_url)
      expect(response).to have_http_status(:see_other)
      expect(flash[:notice]).to eq("Sale was successfully destroyed")
    end

    it "returns 404 for a sale that does not exist" do
      delete sale_path("non-existent")

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /sales/:sale_id/items/:id" do
    it "renders the sale item component", :aggregate_failures do
      sale_item = create(:sale_item)

      get sale_item_path(sale_item.sale, sale_item)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("SaleItems/Show")
    end

    it "returns 404 for an item of another sale" do
      sale_item = create(:sale_item)

      get sale_item_path(create(:sale), sale_item)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /sales/:sale_id/items/:id" do
    it "removes the sale item and redirects to the return path", :aggregate_failures do
      sale_item = create(:sale_item)
      sale = sale_item.sale

      expect {
        delete sale_item_path(sale, sale_item), params: {return_to: edit_sale_path(sale)}
      }.to change(SaleItem, :count).by(-1)

      expect(response).to redirect_to(edit_sale_path(sale))
      expect(flash[:notice]).to eq("Sale item was successfully destroyed")
    end

    it "unlinks the purchase items of the removed sale item", :aggregate_failures do
      sale_item = create(:sale_item)
      purchase_item = create(:purchase_item, sale_item:)

      delete sale_item_path(sale_item.sale, sale_item)

      expect(response).to redirect_to(sale_path(sale_item.sale))
      expect(purchase_item.reload.sale_item).to be_nil
    end

    it "returns 404 and keeps the item when it belongs to another sale", :aggregate_failures do
      sale_item = create(:sale_item)

      delete sale_item_path(create(:sale), sale_item)

      expect(response).to have_http_status(:not_found)
      expect(SaleItem.exists?(sale_item.id)).to be(true)
    end
  end

  describe "POST /sales/:sale_id/pull" do
    let(:sale) { create(:sale, :synced) }

    before do
      allow(Config).to receive(:update_shopify_sales_sync_time)
      allow(Woo::PullSalesJob).to receive_message_chain(:set, :perform_later)
      allow(Shopify::PullSaleJob).to receive(:perform_later)
    end

    it "enqueues the delayed Woo pull and the Shopify pull for the sale", :aggregate_failures do
      post sale_pull_path(sale)

      expect(Woo::PullSalesJob).to have_received(:set).with(wait: 90.seconds)
      expect(Shopify::PullSaleJob).to have_received(:perform_later).with(sale.shopify_store_id, requested_by: admin)
      expect(response).to redirect_to(sales_path)
    end

    it "says the pull was queued" do
      post sale_pull_path(sale)

      expect(flash[:notice]).to include(message: start_with("Started pulling this order from the store."))
    end

    it "does not update the bulk sync timestamp" do
      post sale_pull_path(sale)

      expect(Config).not_to have_received(:update_shopify_sales_sync_time)
    end

    it "returns 404 and enqueues nothing for a sale that does not exist", :aggregate_failures do
      post sale_pull_path("non-existent")

      expect(response).to have_http_status(:not_found)
      expect(Shopify::PullSaleJob).not_to have_received(:perform_later)
    end
  end

  describe "POST /sales/:sale_id/link_purchase_items" do
    it "links purchased products to the sold products and redirects with a notice", :aggregate_failures do
      purchase = create(:purchase)
      sale_item = create(:sale_item, product: purchase.product, variant: purchase.variant, qty: 1)
      purchase_item = create(:purchase_item, purchase:)

      post sale_purchase_item_link_path(sale_item.sale)

      expect(response).to redirect_to(sale_path(sale_item.sale))
      expect(flash[:success]).to eq("Sold products were interlinked with purchased products")
      expect(purchase_item.reload.sale_item).to eq(sale_item)
    end

    it "returns 404 for a sale that does not exist" do
      post sale_purchase_item_link_path("non-existent")

      expect(response).to have_http_status(:not_found)
    end
  end
end
