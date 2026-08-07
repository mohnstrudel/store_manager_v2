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

    describe "payment props" do
      before do
        create(
          :sale,
          status: "processing",
          payment_overdue: true,
          expected_revenue: BigDecimal("900"),
          received_revenue: BigDecimal("300"),
          outstanding_revenue: BigDecimal("600")
        )
      end

      it "includes payment progress for admins" do
        get sales_path

        payment = inertia.props[:sales].first[:payment]
        expect(payment[:progress]).to eq(33)
        expect(payment[:paid]).to eq("300")
        # The payment pie, not the order's own 1 060 total: 300 paid + 600 debt.
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
      expect(sale_props[:warehouse_move_path]).to eq(warehouse_move_path)
      expect(sale_props[:warehouses]).to include(a_hash_including(id: warehouse.id, name: "Berlin Hub"))
    end

    describe "profitability props" do
      let(:sale) do
        create(
          :sale,
          status: "pre-ordered",
          expected_revenue: BigDecimal("300"),
          received_revenue: BigDecimal("100"),
          outstanding_revenue: BigDecimal("200"),
          refunded_revenue: BigDecimal("0")
        )
      end

      before do
        create(:expense_rate, rate_percent: 10)
        product = create(:product)
        sale_item = create(:sale_item, sale:, product:, variant: nil, qty: 1)
        purchase = create(:purchase, product:, amount: 1, item_price: BigDecimal("100"))
        create(:purchase_item, :with_direct_expense, purchase:, sale_item:, shipping_cost: BigDecimal("15"), direct_expense_amount: BigDecimal("5"))
      end

      it "includes profitability data for admins" do
        get sale_path(sale)

        item_profitability = inertia.props[:sale][:sale_items].first[:profitability]
        expect(item_profitability[:purchase_cost]).to eq("120")
      end

      it "omits profitability data for non-admins" do
        log_out
        sign_in create(:user, :manager)

        get sale_path(sale)

        expect(response).to have_http_status(:ok)
        expect(inertia.props[:sale][:sale_items].first[:profitability]).to be_nil
        expect(inertia.props[:sale][:profitability]).to be_nil
      end

      it "includes an order-scoped profit summary that separates direct expenses" do
        get sale_path(sale)

        summary = inertia.props[:sale][:profitability]
        expect(summary).to include(
          scope: "sale",
          expense_rate_percent: 10.0,
          expected_revenue: "300",
          merchandise_cost: "115",
          direct_expenses: "5",
          purchase_cost: "120",
          business_expenses: "30",
          expected_final_profit: "150"
        )
      end

      it "omits the profit summary for a cancelled sale" do
        sale.update!(status: "cancelled")

        get sale_path(sale)

        expect(inertia.props[:sale][:profitability]).to be_nil
      end

      it "carries the projected profit keys as explicit nil when the sale belongs to no plan" do
        get sale_path(sale)

        summary = inertia.props[:sale][:profitability]
        expect(summary).to include(
          projected_revenue: nil,
          projected_business_expenses: nil,
          projected_final_profit: nil
        )
      end
    end

    describe "projected profit props" do
      let(:origin) do
        create(
          :sale,
          status: "pre-ordered",
          shopify_store_id: "gid://shopify/Order/950",
          expected_revenue: BigDecimal("300"),
          received_revenue: BigDecimal("300"),
          outstanding_revenue: BigDecimal("0"),
          refunded_revenue: BigDecimal("0")
        )
      end

      before do
        create(:expense_rate, rate_percent: 15)
        product = create(:product)
        origin_item = create(:sale_item, sale: origin, product:, variant: nil, qty: 1)
        create(
          :purchase_item,
          purchase: create(:purchase, product:, amount: 1, item_price: BigDecimal("700")),
          sale_item: origin_item,
          shipping_cost: BigDecimal("0")
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
            currency: "EUR",
            synced_at: Time.current
          },
          parts: [
            {sequence: 1, provider_part_id: "origin", external_order_id: "950", amount: 300, currency: "EUR"}
          ]
        )
      end

      it "reports the booked loss and the projected profit at once for a deposit with a known contract value" do
        get sale_path(origin)

        summary = inertia.props[:sale][:profitability]
        expect(summary).to include(
          scope: "plan",
          expected_final_profit: "-445",
          projected_revenue: "1 020",
          projected_business_expenses: "153",
          projected_final_profit: "167"
        )
      end
    end

    describe "payment props" do
      let(:sale) { create(:sale, shipping_total: BigDecimal("30")) }

      before do
        product = create(:product)
        create(
          :sale_item,
          sale:,
          product:,
          variant: nil,
          price: BigDecimal("100"),
          expected_revenue: BigDecimal("100"),
          received_revenue: BigDecimal("40")
        )
      end

      it "includes the paid amount, shipping-inclusive total, debt, and progress for admins" do
        get sale_path(sale)

        payment = inertia.props[:sale][:sale_items].first[:payment]
        expect(payment[:paid]).to eq("40")
        expect(payment[:price]).to eq("130")
        expect(payment[:debt]).to eq("90")
        expect(payment[:progress]).to eq(31)
      end

      it "includes payment data for non-admins too, unlike profitability data" do
        log_out
        sign_in create(:user, :manager)

        get sale_path(sale)

        payment = inertia.props[:sale][:sale_items].first[:payment]
        expect(payment[:paid]).to eq("40")
        expect(payment[:price]).to eq("130")
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
  end
end
# rubocop:enable RSpec/MultipleExpectations
