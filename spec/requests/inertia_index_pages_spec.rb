# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Inertia index pages" do
  before { sign_in_as_admin }

  describe "GET /" do
    it "renders the dashboard index component" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Dashboard/Index")
      expect_inertia.to have_props(
        debts_path: debts_path,
        last_orders_pull_path: last_orders_pull_path
      )
    end

    it "passes sales_hook_disabled from Config to the dashboard props" do
      allow(Config).to receive(:sales_hook_disabled?).and_return(true)

      get root_path

      expect(inertia.props[:sales_hook_disabled]).to be(true)
    end
  end

  describe "GET /noop" do
    it "renders the dashboard noop component" do
      get noop_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Dashboard/Noop")
    end
  end

  describe "GET /warehouses" do
    it "renders the warehouses index component" do
      warehouse = create(:warehouse, name: "Main Warehouse")

      get warehouses_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Warehouses/Index")
      expect(inertia.props[:warehouses].first[:id]).to eq(warehouse.id)
      expect(inertia.props[:warehouses].first[:path]).to eq(warehouse_path(warehouse))
    end
  end

  describe "GET /users" do
    it "renders the users index component" do
      user = create(:user, email_address: "team@example.com")

      get users_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Users/Index")
      expect(inertia.props[:users].map { |props| props[:email_address] }).to include(user.email_address)
    end
  end

  describe "GET /purchase_items" do
    it "renders the purchase items index component with pagination and search" do
      shipping_company = create(:shipping_company)
      purchase_item = create(:purchase_item, tracking_number: "TRACK-42", shipping_company:)
      create(:purchase_item, tracking_number: "OTHER", shipping_company:)

      get purchase_items_path, params: {q: "TRACK"}

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("PurchaseItems/Index")
      expect_inertia.to have_props(
        pagination: {current_page: 1, total_pages: 1, total_count: 1, limit: 25},
        search: {q: "TRACK"}
      )
      expect(inertia.props[:purchase_items].first[:id]).to eq(purchase_item.id)
    end
  end
end
