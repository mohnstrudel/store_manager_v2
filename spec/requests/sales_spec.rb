# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sales" do
  before { sign_in_as_admin }

  describe "GET /sales" do
    it "renders the index Inertia component with pagination and search" do
      sale = create(:sale, status: "processing")
      create(:sale, status: "completed")
      create(:sale, status: "cancelled")

      get sales_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Sales/Index")
      expect_inertia.to have_props(
        pagination: {current_page: 1, total_pages: 1, total_count: 1, limit: 50},
        search: {q: ""},
        last_sync_at: nil,
        last_sync_time: nil
      )

      sales = inertia.props[:sales]
      expect(sales.map { |item| item[:id] }).to eq([sale.id])
      expect(sales.first[:customer_name]).to eq(sale.customer.full_name)
    end

    it "filters sales by search query" do
      matching = create(:sale, shopify_name: "HSCM#1746")
      _other = create(:sale, shopify_name: "Other order")

      get sales_path, params: {q: "HSCM"}

      expect_inertia.to have_props(search: {q: "HSCM"})
      expect(inertia.props[:sales].map { |item| item[:id] }).to eq([matching.id])
    end
  end

  describe "GET /sales/:id" do
    it "renders the show Inertia component with nested sale data" do
      customer = create(:customer)
      customer.upsert_shopify_info!(store_id: "gid://shopify/Customer/9341147185481")

      sale = create(
        :sale,
        customer:,
        shopify_store_id: "gid://shopify/Order/7383283466569"
      )
      sale.shopify_info.update!(store_id: "gid://shopify/Order/7383283466569")

      product = create(:product)
      variant = create(:variant, product:)
      sale_item = create(:sale_item, sale:, product:, variant:, qty: 2)
      warehouse = create(:warehouse, name: "Berlin Hub")
      create(:purchase_item, sale_item:, warehouse:, purchase: create(:purchase, product:))
      create(:sale_address, sale:, kind: :shipping)
      create(:sale_address, sale:, kind: :billing, city: "Paris")

      get sale_path(sale)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Sales/Show")

      sale_props = inertia.props[:sale]
      expect(sale_props[:id]).to eq(sale.id)
      expect(sale_props[:customer][:shopify_id_short]).to eq("9341147185481")
      expect(sale_props[:shipping_address][:city]).to eq("Bremerhaven")
      expect(sale_props[:billing_address][:city]).to eq("Paris")
      expect(sale_props[:sale_items].first[:title]).to eq(sale_item.title)
      expect(sale_props[:sale_items].first[:purchase_items].first[:current_warehouse_name]).to eq(
        "Berlin Hub"
      )
    end
  end
end
