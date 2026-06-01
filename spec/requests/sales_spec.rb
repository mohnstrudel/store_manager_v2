# frozen_string_literal: true

require "rails_helper"

# rubocop:disable RSpec/MultipleExpectations
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

  describe "GET /sales/new" do
    it "renders the new Inertia component with form options" do
      customer = create(:customer)
      product = create(:product)

      get new_sale_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Sales/New")
      expect(inertia.props[:sale]).to include(
        id: nil,
        path: "",
        status: nil,
        customer_id: nil,
        note: nil,
        total: "",
        discount_total: "",
        shipping_total: ""
      )
      expect(inertia.props[:sale][:sale_items]).to eq([])
      expect(inertia.props[:options][:customers].pluck(:value)).to include(customer.id)
      expect(inertia.props[:options][:products].pluck(:value)).to include(product.id)
      expect(inertia.props[:options][:status_names]).to eq(Sale.status_names)
    end
  end

  describe "GET /sales/:id/edit" do
    it "renders the edit Inertia component with existing sale data" do
      customer = create(:customer)
      sale = create(:sale, customer:, status: "processing", note: "test note")
      product = create(:product)
      sale_item = create(:sale_item, sale:, product:, qty: 2, price: 19.99)
      create(:sale_address, sale:, kind: :shipping, city: "Berlin")

      get edit_sale_path(sale)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Sales/Edit")
      expect(inertia.props[:sale]).to include(
        id: sale.id,
        path: sale_path(sale),
        status: "processing",
        customer_id: customer.id,
        note: "test note"
      )
      expect(inertia.props[:sale][:shipping_address]).to include(city: "Berlin")
      expect(inertia.props[:sale][:sale_items].first).to include(
        id: sale_item.id,
        product_id: product.id,
        qty: "2",
        price: "19.99",
        _destroy: false
      )
      expect(inertia.props[:options][:status_names]).to eq(Sale.status_names)
    end
  end

  describe "POST /sales" do
    it "rerenders the new page when the form is submitted untouched" do
      post sales_path, params: {
        sale: {
          customer_id: "",
          status: "",
          note: "",
          total: "",
          discount_total: "",
          shipping_total: ""
        }
      }

      expect(response).to redirect_to(new_sale_path)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Sales/New")
      expect(inertia.props[:errors]).to be_present
    end

    it "creates a sale with sale items" do # rubocop:disable RSpec/MultipleExpectations
      customer = create(:customer)
      product = create(:product)

      expect {
        post sales_path, params: {
          sale: {
            customer_id: customer.id,
            status: "processing",
            total: "100.00"
          },
          sale_items: {
            "0" => {
              product_id: product.id,
              qty: "1",
              price: "100.00",
              _destroy: "0"
            }
          }
        }
      }.to change(Sale, :count).by(1)
        .and change(SaleItem, :count).by(1)

      sale = Sale.order(:id).last
      expect(response).to redirect_to(sale_path(sale))
      expect(sale.sale_items.first.product).to eq(product)
    end

    it "redirects to the new page with errors when a sale item is invalid" do
      customer = create(:customer)

      post sales_path, params: {
        sale: {customer_id: customer.id, status: "processing"},
        sale_items: {"0" => {product_id: "", qty: "1", price: "10.00", _destroy: "0"}}
      }

      expect(response).to redirect_to(new_sale_path)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Sales/New")
      expect(inertia.props[:errors]).to be_present
    end
  end

  describe "PATCH /sales/:id" do
    it "updates a sale with sale items" do # rubocop:disable RSpec/MultipleExpectations
      customer = create(:customer)
      product = create(:product)
      sale = create(:sale, customer:, status: "processing")
      sale_item = create(:sale_item, sale:, product:, qty: 1, price: 100)

      patch sale_path(sale), params: {
        sale: {
          customer_id: customer.id,
          status: "completed",
          total: "150.00"
        },
        sale_items: {
          "0" => {
            id: sale_item.id,
            product_id: product.id,
            qty: "3",
            price: "150.00",
            _destroy: "0"
          }
        }
      }

      sale.reload

      expect(response).to redirect_to(sale_path(sale))
      expect(sale.status).to eq("completed")
      expect(sale_item.reload.qty).to eq(3)
      expect(sale_item.price).to eq(BigDecimal("150.00"))
    end

    it "redirects to the edit page with errors when a sale item is invalid" do
      customer = create(:customer)
      sale = create(:sale, customer:)

      patch sale_path(sale), params: {
        sale: {customer_id: customer.id, status: sale.status},
        sale_items: {"0" => {product_id: "", qty: "1", price: "10.00", _destroy: "0"}}
      }

      expect(response).to be_redirect
      expect(response.location).to match(%r{/sales/.+/edit\z})

      # The slug in the redirect URL may differ from the persisted slug because
      # FriendlyId regenerates it (with woo_store_id now present) inside the
      # rolled-back transaction. Request the edit page via the original path so
      # we can verify the errors were stored in the session.
      get edit_sale_path(sale)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Sales/Edit")
      expect(inertia.props[:errors]).to be_present
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
      expect(sale_props[:customer][:path]).to eq(customer_path(customer))
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
# rubocop:enable RSpec/MultipleExpectations
