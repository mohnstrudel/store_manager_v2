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
      expect(sales.pluck(:id)).to eq([sale.id])
      expect(sales.first[:customer_name]).to eq(sale.customer.full_name)
    end

    it "filters sales by search query" do
      matching = create(:sale, shopify_name: "HSCM#1746")
      _other = create(:sale, shopify_name: "Other order")

      get sales_path, params: {q: "HSCM"}

      expect_inertia.to have_props(search: {q: "HSCM"})
      expect(inertia.props[:sales].pluck(:id)).to eq([matching.id])
    end

    describe "sorting" do
      def create_dated_sale(day, **attributes)
        create(:sale, woo_created_at: Time.utc(2024, 1, day), **attributes)
      end

      def listed_ids
        inertia.props[:sales].pluck(:id)
      end

      it "defaults to newest first for an absent or invalid sort" do
        older = create_dated_sale(1)
        newer = create_dated_sale(2)

        [{}, {sort: "bogus"}, {sort: ["oldest"]}].each do |params|
          get sales_path, params: params

          expect_inertia.to have_props(sort: "newest")
          expect(listed_ids).to eq([newer.id, older.id])
        end
      end

      it "lists oldest first and returns the normalized sort" do
        older = create_dated_sale(1)
        newer = create_dated_sale(2)
        create_dated_sale(3, status: "completed")

        get sales_path, params: {sort: "oldest", q: ""}

        expect_inertia.to have_props(sort: "oldest", search: {q: ""})
        expect(listed_ids).to eq([older.id, newer.id])
      end

      it "keeps search results under oldest first for support users" do
        log_out
        sign_in create(:user, :support)
        older = create_dated_sale(1, shopify_name: "HSCM#1")
        newer = create_dated_sale(2, shopify_name: "HSCM#2")
        create_dated_sale(3, shopify_name: "Other order")

        get sales_path, params: {q: "HSCM", sort: "oldest"}

        expect(response).to have_http_status(:ok)
        expect(listed_ids).to eq([older.id, newer.id])
      end

      it "denies users without sales access when listing parameters are supplied" do
        log_out
        sign_in create(:user, :guest)
        create_dated_sale(1)

        get sales_path, params: {sort: "oldest", show_missing_purchases: "1", hide_partial_payments: "1"}

        expect(response).to redirect_to(noop_path)
      end

      it "pages oldest first across the page boundary" do
        sales = (1..51).map { |day| create(:sale, woo_created_at: Time.utc(2024, 1, 1) + day.days) }

        get sales_path, params: {sort: "oldest"}
        expect(listed_ids).to eq(sales.first(50).map(&:id))
        expect_inertia.to have_props(pagination: {current_page: 1, total_pages: 2, total_count: 51, limit: 50})

        get sales_path, params: {sort: "oldest", page: 2}
        expect(listed_ids).to eq([sales.last.id])
      end

      it "returns the normalized criteria with listing props on a partial reload" do
        sale = create_dated_sale(1)

        get sales_path,
          params: {sort: "oldest", q: ""},
          headers: {
            "X-Inertia" => "true",
            "X-Inertia-Partial-Component" => "Sales/Index",
            "X-Inertia-Partial-Data" => "sales,pagination,search,sort"
          }

        expect_inertia.to have_props(
          pagination: {current_page: 1, total_pages: 1, total_count: 1, limit: 50},
          search: {q: ""},
          sort: "oldest"
        )
        expect(listed_ids).to eq([sale.id])
      end
    end

    describe "hiding partial payments" do
      let!(:origin) { create(:sale, woo_created_at: Time.utc(2024, 1, 1), shopify_store_id: "gid://shopify/Order/900", note: "batch") }
      let!(:follow_up) { create(:sale, woo_created_at: Time.utc(2024, 1, 2), shopify_store_id: "gid://shopify/Order/901", note: "batch") }
      let!(:ordinary) { create(:sale, woo_created_at: Time.utc(2024, 1, 3), note: "batch") }

      before do
        SalePaymentPlan.reconcile!(
          attributes: {
            provider: "seal",
            external_id: "subscription-900",
            external_origin_order_id: "900",
            kind: "installments",
            status: "active",
            expected_parts: 2,
            synced_at: Time.current
          },
          parts: [
            {provider_part_id: "900-1", sequence: 1, external_order_id: "900"},
            {provider_part_id: "900-2", sequence: 2, external_order_id: "901"}
          ]
        )
      end

      it "enables the filter only for the exact value 1" do
        [{}, {hide_partial_payments: "0"}, {hide_partial_payments: "true"}, {hide_partial_payments: "yes"}].each do |params|
          get sales_path, params: params.merge(sort: "oldest")

          expect_inertia.to have_props(filters: {hide_partial_payments: false, show_missing_purchases: false})
          expect(inertia.props[:sales].pluck(:id)).to eq([origin.id, follow_up.id, ordinary.id])
        end

        get sales_path, params: {hide_partial_payments: "1", sort: "oldest"}

        expect_inertia.to have_props(
          filters: {hide_partial_payments: true, show_missing_purchases: false},
          sort: "oldest",
          pagination: {current_page: 1, total_pages: 1, total_count: 2, limit: 50}
        )
        expect(inertia.props[:sales].pluck(:id)).to eq([origin.id, ordinary.id])
      end

      it "applies search and sort before and with the filter" do
        get sales_path, params: {q: "batch", sort: "newest", hide_partial_payments: "1"}

        expect_inertia.to have_props(search: {q: "batch"}, filters: {hide_partial_payments: true, show_missing_purchases: false})
        expect(inertia.props[:sales].pluck(:id)).to eq([ordinary.id, origin.id])
      end

      it "returns an empty result instead of falling back to text when an exact Store ID is filtered out" do
        create(:sale, note: "customer asked about 901")

        get sales_path, params: {q: "901", hide_partial_payments: "1"}

        expect(inertia.props[:sales]).to be_empty
        expect_inertia.to have_props(pagination: {current_page: 1, total_pages: 0, total_count: 0, limit: 50})
      end

      it "returns the normalized filter on a partial reload" do
        get sales_path,
          params: {hide_partial_payments: "1"},
          headers: {
            "X-Inertia" => "true",
            "X-Inertia-Partial-Component" => "Sales/Index",
            "X-Inertia-Partial-Data" => "sales,pagination,search,sort,filters"
          }

        expect_inertia.to have_props(filters: {hide_partial_payments: true, show_missing_purchases: false})
      end

      it "serves a fresh response when the checkbox changes but the visible rows do not" do
        follow_up.destroy
        get sales_path
        etag = response.headers["ETag"]

        get sales_path, params: {hide_partial_payments: "1"}, headers: {"If-None-Match" => etag}

        expect(response).to have_http_status(:ok)
        expect_inertia.to have_props(filters: {hide_partial_payments: true, show_missing_purchases: false})
      end
    end

    describe "showing missing purchases" do
      def create_sale_with_line(day: 1, qty: 1, linked: 0, **attributes)
        sale = create(:sale, woo_created_at: Time.utc(2024, 1, 1) + day.days, **attributes)
        product = create(:product)
        sale_item = create(:sale_item, sale:, product:, qty:)
        link_purchase_items(sale_item, linked)
        sale
      end

      def link_purchase_items(sale_item, count)
        return if count.zero?

        purchase = create(:purchase, product: sale_item.product, amount: count)
        create_list(:purchase_item, count, purchase:, sale_item:)
      end

      def listed_ids
        inertia.props[:sales].pluck(:id)
      end

      it "enables the filter only for the exact value 1" do
        short = create_sale_with_line(day: 1)
        covered = create_sale_with_line(day: 2, linked: 1)

        [{}, {show_missing_purchases: "0"}, {show_missing_purchases: "true"}].each do |params|
          get sales_path, params: params.merge(sort: "oldest")

          expect_inertia.to have_props(filters: {hide_partial_payments: false, show_missing_purchases: false})
          expect(listed_ids).to eq([short.id, covered.id])
        end

        get sales_path, params: {show_missing_purchases: "1", sort: "oldest"}

        expect_inertia.to have_props(
          filters: {hide_partial_payments: false, show_missing_purchases: true},
          pagination: {current_page: 1, total_pages: 1, total_count: 1, limit: 50}
        )
        expect(listed_ids).to eq([short.id])
      end

      it "renders every line and purchase link of a matching sale once" do
        sale = create(:sale)
        short_item = create(:sale_item, sale:, product: create(:product), qty: 2)
        covered_item = create(:sale_item, sale:, product: create(:product), qty: 1)
        other_short_item = create(:sale_item, sale:, product: create(:product), qty: 3)
        link_purchase_items(short_item, 1)
        link_purchase_items(covered_item, 1)

        get sales_path, params: {show_missing_purchases: "1"}

        expect(listed_ids).to eq([sale.id])
        expect_inertia.to have_props(pagination: {current_page: 1, total_pages: 1, total_count: 1, limit: 50})
        lines = inertia.props[:sales].first[:sale_items]
        expect(lines.pluck(:id)).to contain_exactly(short_item.id, covered_item.id, other_short_item.id)
        expect(lines.to_h { |line| [line[:id], line[:purchase_items].size] })
          .to eq(short_item.id => 1, covered_item.id => 1, other_short_item.id => 0)
      end

      it "combines with the partial-payment filter, search and sort" do
        origin = create_sale_with_line(day: 1, shopify_store_id: "gid://shopify/Order/900", note: "batch")
        follow_up = create_sale_with_line(day: 2, shopify_store_id: "gid://shopify/Order/901", note: "batch")
        ordinary = create_sale_with_line(day: 3, note: "batch", received_revenue: 100, outstanding_revenue: 100)
        covered = create_sale_with_line(day: 4, linked: 1, note: "batch")
        SalePaymentPlan.reconcile!(
          attributes: {
            provider: "seal",
            external_id: "subscription-900",
            external_origin_order_id: "900",
            kind: "installments",
            status: "active",
            expected_parts: 2,
            synced_at: Time.current
          },
          parts: [
            {provider_part_id: "900-1", sequence: 1, external_order_id: "900"},
            {provider_part_id: "900-2", sequence: 2, external_order_id: "901"}
          ]
        )
        expected = {
          {} => [origin, follow_up, ordinary, covered],
          {hide_partial_payments: "1"} => [origin, ordinary, covered],
          {show_missing_purchases: "1"} => [origin, ordinary],
          {hide_partial_payments: "1", show_missing_purchases: "1"} => [origin, ordinary]
        }

        expected.each do |filters, sales|
          get sales_path, params: filters.merge(q: "batch", sort: "oldest")

          expect(listed_ids).to eq(sales.map(&:id))
          expect_inertia.to have_props(pagination: {current_page: 1, total_pages: 1, total_count: sales.size, limit: 50}, search: {q: "batch"}, sort: "oldest")
        end
      end

      it "returns an empty result when the exact Store ID target has no shortage" do
        create_sale_with_line(linked: 1, shopify_store_id: "gid://shopify/Order/777")
        create_sale_with_line(note: "customer asked about 777")

        get sales_path, params: {q: "777", show_missing_purchases: "1"}

        expect(listed_ids).to be_empty
      end

      it "pages 51 matching sales oldest first among nonmatching orders" do
        matching = (1..51).map { |day| create_sale_with_line(day:) }
        create_sale_with_line(day: 60, linked: 1)

        get sales_path, params: {show_missing_purchases: "1", sort: "oldest"}
        expect(listed_ids).to eq(matching.first(50).map(&:id))
        expect_inertia.to have_props(pagination: {current_page: 1, total_pages: 2, total_count: 51, limit: 50})

        get sales_path, params: {show_missing_purchases: "1", sort: "oldest", page: 2}
        expect(listed_ids).to eq([matching.last.id])
      end

      it "returns both normalized filters on a partial reload" do
        create_sale_with_line

        get sales_path,
          params: {show_missing_purchases: "1"},
          headers: {
            "X-Inertia" => "true",
            "X-Inertia-Partial-Component" => "Sales/Index",
            "X-Inertia-Partial-Data" => "sales,pagination,search,sort,filters"
          }

        expect_inertia.to have_props(filters: {hide_partial_payments: false, show_missing_purchases: true})
      end

      it "serves a fresh response when only an off-page shortage changes" do
        older_short = create_sale_with_line(day: 1)
        50.times { |index| create_sale_with_line(day: 10 + index) }
        get sales_path, params: {show_missing_purchases: "1"}
        etag = response.headers["ETag"]
        first_page_ids = listed_ids
        expect_inertia.to have_props(pagination: {current_page: 1, total_pages: 2, total_count: 51, limit: 50})

        link_purchase_items(older_short.sale_items.first, 1)
        get sales_path, params: {show_missing_purchases: "1"}, headers: {"If-None-Match" => etag}

        expect(response).to have_http_status(:ok)
        expect(listed_ids).to eq(first_page_ids)
        expect_inertia.to have_props(pagination: {current_page: 1, total_pages: 1, total_count: 50, limit: 50})
      end
    end

    describe "conditional requests" do
      def create_dated_sale(day)
        create(:sale, woo_created_at: Time.utc(2024, 1, day))
      end

      def get_with_etag(etag, **params)
        get sales_path, params:, headers: {"If-None-Match" => etag}
      end

      it "serves a fresh response when only the sort changes" do
        older = create_dated_sale(1)
        newer = create_dated_sale(2)
        get sales_path
        newest_etag = response.headers["ETag"]

        get_with_etag(newest_etag, sort: "oldest")

        expect(response).to have_http_status(:ok)
        expect(inertia.props[:sales].pluck(:id)).to eq([older.id, newer.id])
      end

      it "serves a fresh response when only an off-page total changes" do
        50.times { |index| create(:sale, woo_created_at: Time.utc(2024, 3, 1) + index.days) }
        create_dated_sale(1)
        get sales_path
        etag = response.headers["ETag"]
        first_page_ids = inertia.props[:sales].pluck(:id)

        create_dated_sale(2)
        get_with_etag(etag)

        expect(response).to have_http_status(:ok)
        expect(inertia.props[:sales].pluck(:id)).to eq(first_page_ids)
        expect_inertia.to have_props(pagination: {current_page: 1, total_pages: 2, total_count: 52, limit: 50})
      end

      it "serves a fresh response when only the echoed query text changes" do
        create_dated_sale(1)
        get sales_path, params: {q: ""}
        etag = response.headers["ETag"]

        get_with_etag(etag, q: " ")

        expect(response).to have_http_status(:ok)
        expect_inertia.to have_props(search: {q: " "})
      end

      it "answers not modified when nothing changed" do
        create_dated_sale(1)
        get sales_path, params: {sort: "oldest"}

        get_with_etag(response.headers["ETag"], sort: "oldest")

        expect(response).to have_http_status(:not_modified)
      end
    end

    describe "payment props" do
      before do
        create(
          :sale,
          status: "processing",
          payment_overdue: true,
          expected_revenue: BigDecimal(900),
          received_revenue: BigDecimal(300),
          outstanding_revenue: BigDecimal(600)
        )
      end

      it "includes payment progress for admins" do
        get sales_path

        payment = inertia.props[:sales].first[:payment]
        expect(payment[:progress]).to eq(33)
        expect(payment[:paid]).to eq("300")
        expect(payment[:price]).to eq("900")
        expect(payment[:debt]).to eq("600")
        expect(payment[:payment_overdue]).to be(true)
      end

      it "includes payment progress for non-admins too" do
        log_out
        sign_in create(:user, :support)

        get sales_path

        expect(response).to have_http_status(:ok)
        payment = inertia.props[:sales].first[:payment]
        expect(payment[:paid]).to eq("300")
        expect(payment[:payment_overdue]).to be(true)
      end

      it "includes exact payment-plan context" do
        sale = Sale.order(:id).last
        sale.upsert_shopify_info!(store_id: "gid://shopify/Order/100")
        SalePaymentPlan.reconcile!(
          attributes: {
            provider: "seal",
            external_id: "subscription-1",
            external_origin_order_id: "100",
            kind: "installments",
            status: "active",
            expected_parts: 4,
            synced_at: Time.current
          },
          parts: [
            {provider_part_id: "subscription-1:1", sequence: 1, external_order_id: "100"}
          ]
        )

        get sales_path

        expect(inertia.props[:sales].first[:payment_plans].first).to include(
          expected_parts: 4,
          collected_parts: 0,
          is_origin_sale: true
        )
      end
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
        variant_id: sale_item.variant_id,
        qty: "2",
        price: "19.99",
        _destroy: false
      )
      expect(inertia.props[:sale][:sale_items].first[:variant_availability]).to include(
        mode: "base"
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
      variant = product.base_variant

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
              variant_id: variant.id,
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
      expect(sale.sale_items.first.variant).to eq(variant)
    end

    it "redirects with a row-specific error when a Sale item Variant is missing" do
      customer = create(:customer)
      product = create(:product)
      create(:variant, product:, size: create(:size))

      post sales_path, params: {
        sale: {customer_id: customer.id, status: "processing"},
        sale_items: {"0" => {product_id: product.id, variant_id: "", qty: "1", price: "10.00", _destroy: "0"}}
      }

      expect(response).to redirect_to(new_sale_path)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Sales/New")
      expect(inertia.props[:errors]).to include(
        "sale_items.0.variant": "must be selected"
      )
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
      create(
        :purchase_item,
        sale_item:,
        warehouse:,
        purchase: create(:purchase, product:, variant:)
      )
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
      expect(sale_props[:sale_items].first[:purchase_items].first[:current_warehouse_moved_in]).to eq(
        ApplicationController.helpers.format_date(Time.current)
      )
      expect(sale_props[:warehouse_move_path]).to eq(warehouse_move_path)
      expect(sale_props[:warehouses]).to include(a_hash_including(id: warehouse.id, name: "Berlin Hub"))
    end

    describe "profitability props" do
      let(:sale) do
        create(
          :sale,
          status: "pre-ordered",
          expected_revenue: BigDecimal(300),
          received_revenue: BigDecimal(100),
          outstanding_revenue: BigDecimal(200),
          refunded_revenue: BigDecimal(0)
        )
      end

      before do
        create(:expense_rate, rate_percent: 10)
        product = create(:product)
        sale_item = create(:sale_item, sale:, product:, variant: nil, qty: 1)
        purchase = create(:purchase, product:, amount: 1, item_price: BigDecimal(100))
        create(:purchase_item, :with_direct_expense, purchase:, sale_item:, shipping_cost: BigDecimal(15), direct_expense_amount: BigDecimal(5))
      end

      it "includes profitability data for admins" do
        get sale_path(sale)

        item_profitability = inertia.props[:sale][:sale_items].first[:profitability]
        expect(item_profitability[:purchase_cost]).to eq("120")
        expect(item_profitability.keys).to contain_exactly("expected_revenue", "purchase_cost", "expected_final_profit")
      end

      it "omits profitability data for non-admins" do
        log_out
        sign_in create(:user, :manager)

        get sale_path(sale)

        expect(response).to have_http_status(:ok)
        expect(inertia.props[:sale][:sale_items].first[:profitability]).to be_nil
        expect(inertia.props[:sale][:profitability]).to be_nil
      end

      it "includes an order-scoped profit summary that splits the purchase figures" do
        get sale_path(sale)

        summary = inertia.props[:sale][:profitability]
        expect(summary).to include(
          scope: "sale",
          gross_revenue: "300",
          item_price_total: "100",
          purchase_expenses: "20",
          purchase_shipping_cost: "15",
          direct_expenses: "5",
          business_expenses: "30",
          net_profit: "150"
        )
      end

      it "states the two halves of the cash position beside it" do
        Purchase.sole.update!(paid: BigDecimal(60))

        get sale_path(sale)

        summary = inertia.props[:sale][:profitability]
        expect(summary).to include(
          collected_revenue: "100",
          purchase_paid: "60",
          cash_position: "40"
        )
      end

      it "omits values no component reads from the profit summary" do
        get sale_path(sale)

        summary = inertia.props[:sale][:profitability]
        expect(summary).not_to have_key(:expense_rate_percent)
        expect(summary).not_to have_key(:expected_revenue)
        expect(summary).not_to have_key(:outstanding_revenue)
        expect(summary).not_to have_key(:refunded_revenue)
        expect(summary).not_to have_key(:purchase_cost)
        expect(summary).not_to have_key(:merchandise_cost)
        expect(summary).not_to have_key(:expected_final_profit)
        expect(summary).not_to have_key(:realized_profit)
        expect(summary).not_to have_key(:projected_revenue)
        expect(summary).not_to have_key(:projected_business_expenses)
        expect(summary).not_to have_key(:projected_final_profit)
      end

      it "omits the profit summary for a cancelled sale" do
        sale.update!(status: "cancelled")

        get sale_path(sale)

        expect(inertia.props[:sale][:profitability]).to be_nil
      end
    end

    describe "whole-deal profit props" do
      let(:origin) do
        create(
          :sale,
          status: "pre-ordered",
          shopify_store_id: "gid://shopify/Order/950",
          expected_revenue: BigDecimal(300),
          received_revenue: BigDecimal(300),
          outstanding_revenue: BigDecimal(0),
          refunded_revenue: BigDecimal(0)
        )
      end

      before do
        create(:expense_rate, rate_percent: 15)
        product = create(:product)
        origin_item = create(:sale_item, sale: origin, product:, variant: nil, qty: 1)
        create(
          :purchase_item,
          purchase: create(:purchase, product:, amount: 1, item_price: BigDecimal(700)),
          sale_item: origin_item,
          shipping_cost: BigDecimal(0)
        )

        SalePaymentPlan.reconcile!(
          attributes: {
            provider: "seal",
            external_id: "subscription-deposit",
            external_origin_order_id: "950",
            kind: "deposit",
            status: "active",
            expected_parts: 1,
            deposit_percent: 30,
            projected_total: 1020,
            synced_at: Time.current
          },
          parts: [
            {sequence: 1, provider_part_id: "origin", external_order_id: "950", amount: 300}
          ]
        )
      end

      it "measures the whole contract value against the whole cost for a deposit with a known Projected total" do
        get sale_path(origin)

        summary = inertia.props[:sale][:profitability]
        expect(summary).to include(
          scope: "plan",
          gross_revenue: "1 020",
          item_price_total: "700",
          business_expenses: "153",
          net_profit: "167",
          collected_revenue: "300",
          cash_position: "300"
        )
      end
    end

    describe "payment props" do
      let(:sale) { create(:sale, shipping_total: BigDecimal(30)) }

      before do
        product = create(:product)
        create(
          :sale_item,
          sale:,
          product:,
          variant: nil,
          price: BigDecimal(100),
          expected_revenue: BigDecimal(100),
          received_revenue: BigDecimal(40)
        )
      end

      it "includes the shipping-inclusive Price for admins" do
        get sale_path(sale)

        expect(inertia.props[:sale][:sale_items].first[:price]).to eq("130")
      end

      it "includes item Price for non-admins too, unlike profitability data" do
        log_out
        sign_in create(:user, :manager)

        get sale_path(sale)

        expect(inertia.props[:sale][:sale_items].first[:price]).to eq("130")
        expect(inertia.props[:sale][:sale_items].first[:profitability]).to be_nil
      end

      it "includes order-level payment and generic partial context" do
        sale.update!(expected_revenue: 100, received_revenue: 40, outstanding_revenue: 60)

        get sale_path(sale)

        expect(inertia.props[:sale][:payment]).to include(progress: 40, paid: "40", debt: "60")
        expect(inertia.props[:sale]).to include(partially_paid: true, payment_plans: [])
      end
    end

    describe "follow-up payment presentation" do
      let(:origin) { create(:sale, shopify_store_id: "gid://shopify/Order/900") }
      let(:follow_up) do
        create(:sale, customer: origin.customer, shopify_store_id: "gid://shopify/Order/901", note: "Second charge")
      end

      before do
        create(:sale_address, sale: follow_up, kind: :shipping)
        create(:expense_rate, rate_percent: 10)

        SalePaymentPlan.reconcile!(
          attributes: {
            provider: "seal",
            external_id: "subscription-1",
            external_origin_order_id: "900",
            kind: "installments",
            status: "active",
            expected_parts: 2,
            synced_at: Time.current
          },
          parts: [
            {provider_part_id: "part-1", sequence: 1, external_order_id: "900"},
            {provider_part_id: "part-2", sequence: 2, external_order_id: "901"}
          ]
        )
      end

      it "marks the charge as a follow-up payment and withholds profitability, products, and address props" do
        get sale_path(follow_up)

        sale_props = inertia.props[:sale]
        expect(sale_props[:is_follow_up_payment]).to be(true)
        expect(sale_props[:profitability]).to be_nil
        expect(sale_props[:sale_items]).to eq([])
        expect(sale_props).not_to have_key(:shipping_address)
        expect(sale_props).not_to have_key(:billing_address)
        expect(sale_props).not_to have_key(:billing_differs_from_shipping)
        expect(sale_props).not_to have_key(:discount_total)
        expect(sale_props).not_to have_key(:shipping_total)
      end

      it "still reports what a follow-up payment actually knows" do
        get sale_path(follow_up)

        sale_props = inertia.props[:sale]
        expect(sale_props[:id]).to eq(follow_up.id)
        expect(sale_props[:status]).to eq(follow_up.status)
        expect(sale_props[:note]).to eq("Second charge")
        expect(sale_props[:customer][:id]).to eq(follow_up.customer_id)
        expect(sale_props[:total]).to be_present
        expect(sale_props[:payment]).to be_present
      end

      it "leaves the originating order's page unchanged" do
        get sale_path(origin)

        sale_props = inertia.props[:sale]
        expect(sale_props[:is_follow_up_payment]).to be(false)
        expect(sale_props[:profitability]).not_to be_nil
        expect(sale_props).to have_key(:shipping_address)
        expect(sale_props).to have_key(:billing_address)
        expect(sale_props).to have_key(:billing_differs_from_shipping)
        expect(sale_props).to have_key(:discount_total)
        expect(sale_props).to have_key(:shipping_total)
      end

      it "batches sale_items across every related sale instead of querying them one by one" do
        sale_item_queries = []
        subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _started, _finished, _id, payload|
          sale_item_queries << payload[:sql] if payload[:sql].start_with?(%(SELECT "sale_items".* FROM "sale_items"))
        end

        begin
          get sale_path(origin)
        ensure
          ActiveSupport::Notifications.unsubscribe(subscriber)
        end

        expect(response).to have_http_status(:ok)
        expect(sale_item_queries.size).to eq(2)
      end

      it "leaves a Shopify payment_terms order unaffected, since its schedules all belong to the one order" do
        payment_terms_sale = create(:sale, shopify_store_id: "gid://shopify/Order/950")
        SalePaymentPlan.reconcile!(
          attributes: {
            provider: "shopify",
            external_id: "terms-1",
            external_origin_order_id: "950",
            kind: "payment_terms",
            status: "active",
            expected_parts: 2,
            synced_at: Time.current
          },
          parts: [
            {provider_part_id: "sched-1", sequence: 1, external_order_id: "950"},
            {provider_part_id: "sched-2", sequence: 2, external_order_id: "950"}
          ]
        )

        get sale_path(payment_terms_sale)

        sale_props = inertia.props[:sale]
        expect(sale_props[:is_follow_up_payment]).to be(false)
        expect(sale_props[:payment_plans].first).to include(is_origin_sale: true)
        expect(sale_props).to have_key(:shipping_address)
        expect(sale_props).to have_key(:discount_total)
      end
    end
  end

  describe "GET /sales index listing props" do
    it "includes the follow-up payment flag on the listing record" do
      sale = create(:sale)

      get sales_path

      expect(inertia.props[:sales].first).to include(id: sale.id, is_follow_up_payment: false)
    end

    it "includes the normalized settlement status and payment progress" do
      create(:sale, settlement_status: "not_fully_paid", expected_revenue: 1000, received_revenue: 300, outstanding_revenue: 700)

      get sales_path

      sale_props = inertia.props[:sales].first
      expect(sale_props[:settlement_status]).to eq("not_fully_paid")
      expect(sale_props[:payment_progress]).to include(source: "amount", percent: 30, paid: "$300", total: "$1,000", remaining: "$700")
    end

    it "reports no positive status or progress for an economically excluded sale" do
      create(:sale, settlement_status: "not_fully_paid", status: "processing", financial_status: "VOIDED")

      get sales_path

      sale_props = inertia.props[:sales].first
      expect(sale_props[:settlement_status]).to be_nil
      expect(sale_props[:payment_progress]).to be_nil
    end
  end

  describe "GET /sales/:id settlement and progress props" do
    it "includes the normalized settlement status and payment progress" do
      sale = create(:sale, settlement_status: "paid", expected_revenue: 1000, received_revenue: 1000, outstanding_revenue: 0)

      get sale_path(sale)

      sale_props = inertia.props[:sale]
      expect(sale_props[:settlement_status]).to eq("paid")
      expect(sale_props[:payment_progress]).to include(source: "amount", percent: 100)
    end

    it "reports no positive status or progress for an economically excluded sale" do
      sale = create(:sale, settlement_status: "paid", status: "refunded")

      get sale_path(sale)

      sale_props = inertia.props[:sale]
      expect(sale_props[:settlement_status]).to be_nil
      expect(sale_props[:payment_progress]).to be_nil
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations
