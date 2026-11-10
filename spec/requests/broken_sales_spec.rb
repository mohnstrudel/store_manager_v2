# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Broken sales" do
  before { sign_in_as_admin }

  def record_failure(store_order_id, store_name: "woo", sentry_event_id: nil, message: "Import failed")
    Sale::ImportFailure.record(store_name:, store_order_id:, message:, sentry_event_id:, failed_at: Time.zone.local(2026, 11, 9, 14, 5))
    Sale::ImportFailure.find_by!(store_name:, store_order_id:)
  end

  def woo_sale(store_order_id, status: "processing")
    create(:sale, status:, shopify_id: nil, woo_store_id: store_order_id)
  end

  def record_enqueue_transactions(job_class)
    calls = []
    allow(job_class).to receive(:perform_later) { calls << ActiveRecord::Base.connection.open_transactions }
    calls
  end

  describe "GET /broken_sales" do
    it "renders live counters, evidence, impact, and historical repair candidates" do
      product = create(:product)
      active_variant = create(:variant, :with_version, product:, version_value: "Active")
      historical_variant = create(:variant, :with_color, product:, color_value: "Archive")
      purchase = create(:purchase, product:, variant: active_variant, order_reference: "BROKEN-42")
      create(:purchase_item, purchase:)
      historical_variant.update!(deactivated_at: Time.current)
      purchase.update_columns(variant_id: nil)

      get broken_sales_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("BrokenSales/Index")
      expect_inertia.to have_props(
        issue_type: "purchases",
        filter: "",
        counts: {
          sale_items: 0,
          import_failures: 0,
          purchases: 1,
          purchase_item_links: 0,
          sku_collisions: 0,
          shopify_conflicts: 0
        },
        filters: [
          {value: "missing_product", label: "Missing Product"},
          {value: "missing_variant", label: "Missing Variant"},
          {value: "product_mismatch", label: "Product / Variant mismatch"}
        ]
      )
      issue = inertia.props[:issues].sole
      aggregate_failures do
        expect(issue).to include(
          id: purchase.id,
          reference: "BROKEN-42",
          reason: "missing_variant",
          product_title: product.full_title,
          current_variant_label: "Missing Variant",
          inventory_units: 1,
          linked_units: 0
        )
        expect(issue[:candidates]).to contain_exactly(
          {value: active_variant.id, label: active_variant.title, base_model: false},
          {value: historical_variant.id, label: "#{historical_variant.title} (Historical)", base_model: false}
        )
      end
    end

    it "does not run a per-row reason or repair-candidate query across distinct products" do
      4.times do
        purchase = create(:purchase, product: create(:product))
        purchase.update_columns(variant_id: nil)
      end

      per_row_queries = []
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _started, _finished, _id, payload|
        sql = payload[:sql]
        per_row_queries << sql if
          sql.start_with?(%(SELECT 1 AS one FROM "purchases")) ||
            sql.include?(%("variants"."product_id" = $))
      end

      begin
        get broken_sales_path
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      expect(response).to have_http_status(:ok)
      expect(per_row_queries).to be_empty
    end

    it "keeps the selected tab, reason filter, and page in the URL-backed contract" do
      product = create(:product)
      26.times do
        purchase = create(:purchase, product:)
        purchase.update_columns(variant_id: nil)
      end

      get broken_sales_path, params: {
        issue_type: "purchases",
        reason: "missing_variant",
        page: 2
      }

      expect_inertia.to have_props(
        issue_type: "purchases",
        filter: "missing_variant",
        pagination: {
          current_page: 2,
          total_pages: 2,
          total_count: 26,
          limit: 25
        }
      )
      expect(inertia.props[:issues].size).to eq(1)
    end

    it "shows live link evidence and replacement impact" do
      original_product = create(:product)
      target_product = create(:product)
      mismatch = create(
        :purchase_item,
        purchase: create(:purchase, product: original_product),
        sale_item: create(:sale_item, product: original_product, qty: 2)
      )
      exact_inventory = create(
        :purchase_item,
        purchase: create(:purchase, product: target_product)
      )
      mismatch.sale_item.update_columns(
        product_id: target_product.id,
        variant_id: target_product.base_variant.id
      )

      get broken_sales_path, params: {
        issue_type: "purchase_item_links"
      }

      issue = inertia.props[:issues].sole
      aggregate_failures do
        expect(issue).to include(
          id: mismatch.id,
          reason: "sale_item_identity",
          purchase_id: mismatch.purchase_id,
          sale_item_id: mismatch.sale_item_id,
          exact_replacements_available: 1,
          remaining_capacity_after_unlink: 2
        )
        expect(issue[:exact_replacement_ids]).to contain_exactly(exact_inventory.id)
      end
    end

    it "does not run a query per link row" do
      count_queries = lambda do
        queries = 0
        subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _started, _finished, _id, payload|
          queries += 1 unless payload[:cached] || %w[SCHEMA TRANSACTION].include?(payload[:name])
        end

        begin
          get broken_sales_path, params: {issue_type: "purchase_item_links"}
        ensure
          ActiveSupport::Notifications.unsubscribe(subscriber)
        end

        queries
      end
      add_link_with_replacement = lambda do
        original_product = create(:product)
        target_product = create(:product)
        mismatch = create(
          :purchase_item,
          purchase: create(:purchase, product: original_product),
          sale_item: create(:sale_item, product: original_product, qty: 2)
        )
        create(:purchase_item, purchase: create(:purchase, product: target_product))
        mismatch.sale_item.update_columns(product_id: target_product.id, variant_id: target_product.base_variant.id)
      end

      add_link_with_replacement.call
      count_queries.call
      baseline = count_queries.call
      5.times { add_link_with_replacement.call }

      expect(count_queries.call).to eq(baseline)
      expect(inertia.props[:issues].size).to eq(6)
      expect(inertia.props[:issues]).to all(include(exact_replacements_available: 1))
    end

    it "renders every member of a three-variant collision group with edit links and no repair control" do
      product_a = create(:product)
      product_b = create(:product)
      product_c = create(:product)
      variant_a = create(:variant, product: product_a, sku: "dup-1")
      variant_b = create(:variant, product: product_b, sku: "dup-1")
      variant_c = create(:variant, product: product_c, sku: "dup-1")

      get broken_sales_path, params: {issue_type: "sku_collisions"}

      expect_inertia.to have_props(
        issue_type: "sku_collisions",
        filter: "",
        counts: {
          sale_items: 0,
          import_failures: 0,
          purchases: 0,
          purchase_item_links: 0,
          sku_collisions: 3,
          shopify_conflicts: 0
        }
      )
      expect(inertia.props[:issues].size).to eq(3)
      issue = inertia.props[:issues].find { |row| row[:id] == variant_a.id }
      aggregate_failures do
        expect(issue).to include(
          kind: "sku_collision",
          sku: "dup-1",
          product_id: product_a.id,
          product_title: product_a.full_title,
          variant_label: variant_a.title,
          edit_path: edit_product_path(product_a)
        )
        expect(issue).not_to have_key(:candidates)
        expect(issue[:colliding_with]).to contain_exactly(
          {
            product_id: product_b.id,
            product_title: product_b.full_title,
            variant_id: variant_b.id,
            variant_label: variant_b.title,
            edit_path: edit_product_path(product_b)
          },
          {
            product_id: product_c.id,
            product_title: product_c.full_title,
            variant_id: variant_c.id,
            variant_label: variant_c.title,
            edit_path: edit_product_path(product_c)
          }
        )
      end
    end

    it "renders stored Shopify import conflicts with the colliding variant and Shopify options" do
      product = create(:product)
      holder = create(:variant, product:, sku: "holder-sku")
      conflict = create(
        :variant_import_conflict,
        product:,
        conflicting_variant: holder,
        store_id: "gid://shopify/ProductVariant/42",
        sku: "incoming-sku",
        options: [{"name" => "Edition", "value" => "B"}, {"name" => "Version", "value" => "A"}]
      )

      get broken_sales_path, params: {issue_type: "shopify_conflicts"}

      expect_inertia.to have_props(
        issue_type: "shopify_conflicts",
        counts: {sale_items: 0, import_failures: 0, purchases: 0, purchase_item_links: 0, sku_collisions: 0, shopify_conflicts: 1}
      )
      expect(inertia.props[:issues].sole).to include(
        kind: "shopify_conflict",
        id: conflict.id,
        sku: "incoming-sku",
        store_id: "gid://shopify/ProductVariant/42",
        shopify_options: [{name: "Edition", value: "B"}, {name: "Version", value: "A"}],
        product_id: product.id,
        product_title: product.full_title,
        edit_path: edit_product_path(product),
        conflicting_variant_label: holder.title,
        conflicting_variant_sku: "holder-sku"
      )
    end

    it "serves the page at /broken_sales and redirects the old address with its query" do
      expect(broken_sales_path).to eq("/broken_sales")

      get "/variant_assignment_issues?issue_type=sale_items&scope=closed"

      expect(response).to redirect_to("/broken_sales?issue_type=sale_items&scope=closed")
      expect(response).to have_http_status(:moved_permanently)
    end

    it "names the page Broken Sales in the breadcrumb" do
      get broken_sales_path

      expect(inertia.props[:breadcrumb]).to eq("Broken Sales")
    end

    it "denies the page to non-administrators" do
      log_out
      sign_in(create(:user, :manager))

      get broken_sales_path

      expect(response).to redirect_to(noop_path)
    end

    context "with broken order lines" do
      def broken_line(status:, revenue:, product: create(:product), sale: create(:sale, status:))
        create(:sale_item, sale:, product:, expected_revenue: revenue).tap do |line|
          line.update_columns(variant_id: nil)
        end
      end

      def row_ids
        inertia.props[:issues].pluck(:id)
      end

      it "defaults to Orders with prioritized rows" do
        purchase = create(:purchase)
        purchase.update_columns(variant_id: nil)
        cancelled = broken_line(status: "cancelled", revenue: 30)
        completed = broken_line(status: "completed", revenue: 50)
        first_active = broken_line(status: "processing", revenue: 100)
        second_active = broken_line(status: "pre-ordered", revenue: 100)

        get broken_sales_path

        expect_inertia.to have_props(
          issue_type: "sale_items",
          scope: "all",
          product_id: nil,
          product_title: nil
        )
        expect(row_ids).to eq([second_active, first_active, completed, cancelled].map(&:id))
      end

      it "keeps Purchases as the default when no order line is broken" do
        purchase = create(:purchase)
        purchase.update_columns(variant_id: nil)

        get broken_sales_path

        expect_inertia.to have_props(issue_type: "purchases", scope: nil, product_id: nil)
      end

      it "chooses the default tab from the tab counts without a second look at the broken order lines" do
        broken_line(status: "processing", revenue: 10)
        line_lookups = []
        subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _started, _finished, _id, payload|
          line_lookups << payload[:sql] if payload[:sql].start_with?(%(SELECT 1 AS one FROM "sale_items"))
        end

        begin
          get broken_sales_path
        ensure
          ActiveSupport::Notifications.unsubscribe(subscriber)
        end

        expect_inertia.to have_props(issue_type: "sale_items")
        expect(line_lookups).to be_empty
      end

      it "describes an order row with its store, status, customer, amount, and product" do
        product = create(:product)
        customer = create(:customer, first_name: "Ada", last_name: "Lovelace")
        sale = create(:sale, status: "partially-paid", customer:, shopify_id: nil, woo_store_id: "4242")
        line = broken_line(status: nil, revenue: 1234, product:, sale:)

        get broken_sales_path

        expect(inertia.props[:issues].sole).to include(
          kind: "sale_item",
          id: line.id,
          reference: "Order 4242, item #{line.id}",
          order_title: "4242",
          store_type: "woo",
          import_failure: nil,
          status: "Partially Paid",
          customer_name: "Ada Lovelace",
          amount: "$1,234",
          product_title: product.full_title,
          current_variant_label: "Missing Variant",
          record_path: sale_path(sale)
        )
      end

      it "shows the unresolved import failure of an order with its message and pull path" do
        sale = woo_sale("88")
        broken_line(status: nil, revenue: 10, sale:)
        record_failure("88", message: "Line 2: Woo product 5 was not found", sentry_event_id: "abc123")

        get broken_sales_path

        expect(inertia.props[:issues].sole[:import_failure]).to eq(
          "message" => "Line 2: Woo product 5 was not found",
          "last_failed_at" => ApplicationController.helpers.format_datetime(Time.zone.local(2026, 11, 9, 14, 5)),
          "pull_path" => sale_pull_path(sale),
          "sentry_url" => "https://handsomecake-goodies.sentry.io/issues/?query=abc123"
        )
      end

      it "lists unresolved import failures by store order in the Import failures tab with its count and no filters" do
        sale = woo_sale("88")
        record_failure("88", sentry_event_id: "abc123")
        record_failure("gid://shopify/Order/5150", store_name: "shopify", message: "Shopify order failed")
        record_failure("99")
        Sale::ImportFailure.resolve(store_name: "woo", store_order_id: "99")

        get broken_sales_path, params: {issue_type: "import_failures", reason: "missing_variant"}

        expect_inertia.to have_props(
          issue_type: "import_failures",
          view: nil,
          scope: nil,
          filter: "",
          filters: [],
          pagination: {current_page: 1, total_pages: 1, total_count: 2, limit: 25}
        )
        expect(inertia.props[:counts]).to include(import_failures: 2)
        failed_at = ApplicationController.helpers.format_datetime(Time.zone.local(2026, 11, 9, 14, 5))
        expect(inertia.props[:issues]).to contain_exactly(
          a_hash_including(
            kind: "import_failure",
            store_type: "woo",
            order_title: "88",
            record_path: sale_path(sale),
            message: "Import failed",
            first_failed_at: failed_at,
            last_failed_at: failed_at,
            failure_count: 1,
            pull_path: sale_pull_path(sale),
            sentry_url: "https://handsomecake-goodies.sentry.io/issues/?query=abc123"
          ),
          a_hash_including(
            kind: "import_failure",
            store_type: "shopify",
            order_title: "5150",
            record_path: nil,
            message: "Shopify order failed",
            pull_path: broken_sales_import_failure_pull_path(Sale::ImportFailure.find_by!(store_name: "shopify")),
            sentry_url: nil
          )
        )
      end

      it "keeps the scope, Product, and page in the URL-backed contract and offers no issue filter" do
        product = create(:product)
        lines = Array.new(26) { broken_line(status: "trash", revenue: 10, product:) }
        broken_line(status: "processing", revenue: 10, product:)
        broken_line(status: "trash", revenue: 10)

        get broken_sales_path, params: {
          issue_type: "sale_items",
          scope: "closed",
          product_id: product.id,
          reason: "product_mismatch",
          page: 2
        }

        expect_inertia.to have_props(
          issue_type: "sale_items",
          scope: "closed",
          product_id: product.id,
          product_title: product.full_title,
          filter: "",
          filters: [],
          pagination: {current_page: 2, total_pages: 2, total_count: 26, limit: 25}
        )
        expect(row_ids).to eq([lines.first.id])
      end

      it "filters the active scope and falls back to all for an unknown scope" do
        active = broken_line(status: "processing", revenue: 10)
        closed = broken_line(status: "refunded", revenue: 10)

        get broken_sales_path, params: {issue_type: "sale_items", scope: "active"}
        expect(row_ids).to eq([active.id])

        get broken_sales_path, params: {issue_type: "sale_items", scope: "nonsense"}
        expect_inertia.to have_props(scope: "all")
        expect(row_ids).to eq([active.id, closed.id])
      end

      it "lists Products by broken orders in the products view" do
        busy = create(:product)
        quiet = create(:product)
        historical = create(:variant, :with_version, product: busy, version_value: "Old")
        historical.update!(deactivated_at: Time.current)
        2.times { broken_line(status: "cancelled", revenue: 40, product: busy) }
        broken_line(status: "processing", revenue: 55, product: busy)
        broken_line(status: "completed", revenue: 500, product: quiet)

        get broken_sales_path, params: {issue_type: "sale_items", view: "products"}

        expect_inertia.to have_props(
          issue_type: "sale_items",
          view: "products",
          pagination: {current_page: 1, total_pages: 1, total_count: 2, limit: 25}
        )
        expect(inertia.props[:issues]).to match([
          a_hash_including(
            kind: "product",
            id: busy.id,
            product_title: busy.full_title,
            order_count: 3,
            active_order_count: 1,
            closed_line_count: 2,
            revenue: "$135",
            candidates: [
              {value: busy.base_variant.id, label: busy.base_variant.title, base_model: true},
              {value: historical.id, label: "#{historical.title} (Historical)", base_model: false}
            ]
          ),
          a_hash_including(kind: "product", id: quiet.id, order_count: 1, closed_line_count: 0, revenue: "$500")
        ])
      end

      it "defaults to the orders view and ignores an unknown view" do
        broken_line(status: "processing", revenue: 10)

        get broken_sales_path, params: {issue_type: "sale_items", view: "nonsense"}
        expect_inertia.to have_props(view: "orders")

        get broken_sales_path, params: {issue_type: "sale_items", view: "failures"}
        expect_inertia.to have_props(view: "orders")

        get broken_sales_path, params: {issue_type: "purchases", view: "products"}
        expect_inertia.to have_props(view: nil)
      end

      it "does not run a query per Product row" do
        count_queries = lambda do
          queries = 0
          subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _started, _finished, _id, payload|
            queries += 1 unless payload[:cached] || %w[SCHEMA TRANSACTION].include?(payload[:name])
          end

          begin
            get broken_sales_path, params: {issue_type: "sale_items", view: "products"}
          ensure
            ActiveSupport::Notifications.unsubscribe(subscriber)
          end

          queries
        end

        broken_line(status: "processing", revenue: 10)
        count_queries.call
        baseline = count_queries.call

        5.times { broken_line(status: "cancelled", revenue: 10) }

        expect(count_queries.call).to eq(baseline)
      end

      it "does not run a query per order row" do
        count_queries = lambda do
          queries = 0
          subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _started, _finished, _id, payload|
            queries += 1 unless payload[:cached] || %w[SCHEMA TRANSACTION].include?(payload[:name])
          end

          begin
            get broken_sales_path, params: {issue_type: "sale_items"}
          ensure
            ActiveSupport::Notifications.unsubscribe(subscriber)
          end

          queries
        end

        broken_line(status: "processing", revenue: 10)
        count_queries.call
        baseline = count_queries.call

        5.times do |index|
          sale = create(:sale, status: "processing", customer: create(:customer), woo_store_id: "woo-#{index}")
          broken_line(status: nil, revenue: 10, sale:)
        end

        expect(count_queries.call).to eq(baseline)
      end

      it "does not run a query per order row with an import failure" do
        count_queries = lambda do
          queries = 0
          subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _started, _finished, _id, payload|
            queries += 1 unless payload[:cached] || %w[SCHEMA TRANSACTION].include?(payload[:name])
          end

          begin
            get broken_sales_path, params: {issue_type: "sale_items"}
          ensure
            ActiveSupport::Notifications.unsubscribe(subscriber)
          end

          queries
        end
        add_failed_order = lambda do |index|
          broken_line(status: nil, revenue: 10, sale: woo_sale("failed-#{index}"))
          record_failure("failed-#{index}", message: "Order #{index} failed")
        end

        add_failed_order.call(0)
        count_queries.call
        baseline = count_queries.call
        (1..4).each { |index| add_failed_order.call(index) }

        expect(count_queries.call).to eq(baseline)
        expect(inertia.props[:issues].size).to eq(5)
        expect(inertia.props[:issues].pluck(:import_failure)).to all(include("message" => a_string_starting_with("Order ")))
      end
    end
  end

  describe "PATCH /broken_sales/purchases/:id" do
    it "repairs from historical candidates and returns to the URL-backed view" do
      product = create(:product)
      historical_variant = create(:variant, :with_version, product:)
      purchase = create(:purchase, product:, variant: historical_variant)
      historical_variant.update!(deactivated_at: Time.current)
      purchase.update_columns(variant_id: nil)
      return_to = broken_sales_path(
        issue_type: "purchases",
        reason: "missing_variant",
        page: 2
      )

      patch broken_sales_purchase_path(purchase), params: {
        purchase: {variant_id: historical_variant.id},
        return_to:
      }

      aggregate_failures do
        expect(response).to redirect_to(return_to)
        expect(purchase.reload.variant_id).to eq(historical_variant.id)
      end
    end

    it "redirects with an inline error for an invalid candidate" do
      product = create(:product)
      purchase = create(:purchase, product:)
      purchase.update_columns(variant_id: nil)

      patch broken_sales_purchase_path(purchase), params: {
        purchase: {variant_id: create(:product).base_variant.id},
        return_to: broken_sales_path
      }

      expect(response).to redirect_to(broken_sales_path)
      follow_redirect!
      expect(inertia.props[:errors][:variant_id]).to eq(
        "Variant is not an available repair candidate"
      )
    end

    it "accepts a stale already-resolved row as a successful no-op" do
      purchase = create(:purchase)

      patch broken_sales_purchase_path(purchase), params: {
        purchase: {variant_id: purchase.variant_id},
        return_to: broken_sales_path
      }

      expect(response).to redirect_to(broken_sales_path)
      expect(flash[:notice]).to eq("This Purchase already has a Variant. Nothing was changed.")
    end

    it "keeps a concurrently changed unresolved row retryable" do
      purchase = create(:purchase)
      allow(Variant::AssignmentRepair).to receive(:repair_purchase).and_raise(
        PurchaseItem::Linkable::StaleLinkState
      )

      patch broken_sales_purchase_path(purchase), params: {
        purchase: {variant_id: purchase.variant_id},
        return_to: broken_sales_path
      }

      expect(response).to redirect_to(broken_sales_path)
      follow_redirect!
      expect(inertia.props[:errors][:base]).to eq(
        "This issue changed while it was being repaired. Review it and try again"
      )
    end

    it "denies non-administrators without invoking the silent repair command" do
      purchase = create(:purchase)
      log_out
      sign_in(create(:user, :manager))
      allow(Variant::AssignmentRepair).to receive(:repair_purchase)

      patch broken_sales_purchase_path(purchase), params: {
        purchase: {variant_id: purchase.variant_id}
      }

      expect(response).to redirect_to(noop_path)
      expect(Variant::AssignmentRepair).not_to have_received(:repair_purchase)
    end
  end

  describe "PATCH /broken_sales/sale_items/:id" do
    it "repairs the SaleItem through the silent command" do
      sale_item = create(:sale_item)
      sale_item.update_columns(variant_id: nil)

      patch broken_sales_sale_item_path(sale_item), params: {
        sale_item: {variant_id: sale_item.product.base_variant.id},
        return_to: broken_sales_path(issue_type: "sale_items")
      }

      expect(sale_item.reload.variant_id).to eq(sale_item.product.base_variant.id)
      expect(response).to redirect_to(
        broken_sales_path(issue_type: "sale_items")
      )
      expect(sale_item.audits.last).to have_attributes(
        action: "update",
        audited_changes: {"variant_id" => [nil, sale_item.product.base_variant.id]},
        user: admin
      )
    end

    it "queues one pull of the order after the repair commits when the order has an unresolved import failure" do
      sale = woo_sale("88")
      sale_item = create(:sale_item, sale:)
      sale_item.update_columns(variant_id: nil)
      record_failure("88")
      enqueues = record_enqueue_transactions(Woo::PullSalesJob)
      baseline = ActiveRecord::Base.connection.open_transactions

      patch broken_sales_sale_item_path(sale_item), params: {sale_item: {variant_id: sale_item.product.base_variant.id}}

      expect(Woo::PullSalesJob).to have_received(:perform_later).with(id: "88", requested_by: admin).once
      expect(enqueues).to eq([baseline])
      expect(flash[:notice]).to eq("Fixed: 1 unit can now be reserved. Queued a new pull of the order from the store.")
    end

    it "names the reserved units and the debt the repair unblocked" do
      product = create(:product)
      red = create(:variant, :with_color, product:, color_value: "Red")
      sale_item = create(:sale_item, product:, variant: red, qty: 2)
      sale_item.update_columns(variant_id: nil)

      patch broken_sales_sale_item_path(sale_item), params: {sale_item: {variant_id: red.id}}

      expect(flash[:notice]).to eq(
        "Fixed: 2 units can now be reserved, and this sale now counts in what we owe for #{product.full_title} → #{red.title}."
      )
    end

    it "says history now records the Variant for a closed order line" do
      sale_item = create(:sale_item, sale: create(:sale, status: "cancelled"))
      sale_item.update_columns(variant_id: nil)

      patch broken_sales_sale_item_path(sale_item), params: {sale_item: {variant_id: sale_item.product.base_variant.id}}

      expect(flash[:notice]).to eq("Fixed: history now records the Variant for this line.")
    end

    it "says nothing was changed for a no-op" do
      sale_item = create(:sale_item)

      patch broken_sales_sale_item_path(sale_item), params: {sale_item: {variant_id: sale_item.product.base_variant.id}}

      expect(flash[:notice]).to eq("This line already has a Variant. Nothing was changed.")
    end

    it "queues nothing for a no-op repair or a line without an unresolved failure" do
      fixed = create(:sale_item, sale: woo_sale("88"))
      record_failure("88")
      unfailed = create(:sale_item, sale: woo_sale("89"))
      unfailed.update_columns(variant_id: nil)
      allow(Woo::PullSalesJob).to receive(:perform_later)
      allow(Shopify::PullSaleJob).to receive(:perform_later)

      patch broken_sales_sale_item_path(fixed), params: {sale_item: {variant_id: fixed.product.base_variant.id}}
      patch broken_sales_sale_item_path(unfailed), params: {sale_item: {variant_id: unfailed.product.base_variant.id}}

      expect(unfailed.reload.variant_id).to eq(unfailed.product.base_variant.id)
      expect(Woo::PullSalesJob).not_to have_received(:perform_later)
      expect(Shopify::PullSaleJob).not_to have_received(:perform_later)
    end
  end

  describe "POST /broken_sales/products/:product_id/closed_order_repair" do
    def broken_line(status:, product:)
      create(:sale_item, sale: create(:sale, status:), product:).tap do |line|
        line.update_columns(variant_id: nil)
      end
    end

    let(:product) { create(:product) }
    let(:return_to) { broken_sales_path(issue_type: "sale_items", view: "products") }

    it "assigns the Variant to closed orders and reports the counts" do
      closed = broken_line(status: "cancelled", product:)
      linked = broken_line(status: "refunded", product:)
      active = broken_line(status: "processing", product:)
      variant = product.base_variant
      create(:purchase_item, purchase: create(:purchase, product:)).update_columns(sale_item_id: linked.id)

      post broken_sales_product_closed_order_repair_path(product), params: {
        closed_order_repair: {variant_id: variant.id},
        return_to:
      }

      expect(response).to redirect_to(return_to)
      expect(flash[:notice]).to eq("Fixed: history now records the Variant for 1 closed line. Skipped 1 line.")
      expect([closed, linked, active].map { |line| line.reload.variant_id }).to eq([variant.id, nil, nil])
      expect(closed.audits.last).to have_attributes(audited_changes: {"variant_id" => [nil, variant.id]}, user: admin)
      expect([linked, active].map { |line| line.audits.count }).to eq([1, 1])
    end

    it "queues one pull per repaired order with an unresolved import failure after the repairs commit" do
      sale = woo_sale("88", status: "cancelled")
      2.times { create(:sale_item, sale:, product:).update_columns(variant_id: nil) }
      broken_line(status: "cancelled", product:)
      record_failure("88")
      enqueues = record_enqueue_transactions(Woo::PullSalesJob)
      baseline = ActiveRecord::Base.connection.open_transactions

      post broken_sales_product_closed_order_repair_path(product), params: {
        closed_order_repair: {variant_id: product.base_variant.id},
        return_to:
      }

      expect(Woo::PullSalesJob).to have_received(:perform_later).with(id: "88", requested_by: admin).once
      expect(enqueues).to eq([baseline])
      expect(flash[:notice]).to eq("Fixed: history now records the Variant for 3 closed lines. Queued a new pull of 1 order from the store.")
    end

    it "reports lines that failed" do
      allow(Variant::AssignmentRepair).to receive(:repair_closed_sale_items).and_return(
        Variant::AssignmentRepair::ClosedOrderRepair.new(repaired: 0, skipped: 0, failed: 2, repaired_sale_ids: [], queued_pulls: 0)
      )

      post broken_sales_product_closed_order_repair_path(product), params: {
        closed_order_repair: {variant_id: product.base_variant.id},
        return_to:
      }

      expect(flash[:notice]).to eq("Assigned the Variant to 0 lines. Could not assign 2 lines. Try again.")
    end

    it "redirects with an inline error for a Variant of another Product" do
      line = broken_line(status: "cancelled", product:)

      post broken_sales_product_closed_order_repair_path(product), params: {
        closed_order_repair: {variant_id: create(:product).base_variant.id},
        return_to:
      }

      expect(response).to redirect_to(return_to)
      expect(line.reload.variant_id).to be_nil
      follow_redirect!
      expect(inertia.props[:errors][:variant_id]).to eq("Variant is not an available repair candidate")
    end

    it "denies non-administrators without invoking the repair command" do
      log_out
      sign_in(create(:user, :manager))
      allow(Variant::AssignmentRepair).to receive(:repair_closed_sale_items)

      post broken_sales_product_closed_order_repair_path(product), params: {
        closed_order_repair: {variant_id: product.base_variant.id}
      }

      expect(response).to redirect_to(noop_path)
      expect(Variant::AssignmentRepair).not_to have_received(:repair_closed_sale_items)
    end
  end

  describe "PATCH /broken_sales/purchase_item_links/:id" do
    it "repairs the incompatible link through the silent command" do
      original_product = create(:product)
      target_product = create(:product)
      sale_item = create(:sale_item, product: original_product)
      mismatch = create(
        :purchase_item,
        purchase: create(:purchase, product: original_product),
        sale_item:
      )
      exact_inventory = create(
        :purchase_item,
        purchase: create(:purchase, product: target_product)
      )
      sale_item.update_columns(
        product_id: target_product.id,
        variant_id: target_product.base_variant.id
      )

      patch broken_sales_purchase_item_link_path(mismatch), params: {
        return_to: broken_sales_path(
          issue_type: "purchase_item_links"
        )
      }

      expect(response).to redirect_to(
        broken_sales_path(issue_type: "purchase_item_links")
      )
      expect(mismatch.reload.sale_item_id).to be_nil
      expect(exact_inventory.reload.sale_item_id).to eq(sale_item.id)
    end

    it "says nothing was changed for a link that no longer needs repair" do
      product = create(:product)
      purchase_item = create(:purchase_item, purchase: create(:purchase, product:), sale_item: create(:sale_item, product:))

      patch broken_sales_purchase_item_link_path(purchase_item), params: {
        return_to: broken_sales_path(issue_type: "purchase_item_links")
      }

      expect(response).to redirect_to(broken_sales_path(issue_type: "purchase_item_links"))
      expect(flash[:notice]).to eq("This PurchaseItem link no longer needs repair. Nothing was changed.")
    end

    it "keeps a concurrently changed unresolved link retryable" do
      purchase_item = create(:purchase_item)
      allow(
        Variant::AssignmentRepair
      ).to receive(:repair_purchase_item_link).and_raise(
        PurchaseItem::Linkable::StaleLinkState
      )

      patch broken_sales_purchase_item_link_path(purchase_item), params: {
        return_to: broken_sales_path(
          issue_type: "purchase_item_links"
        )
      }

      expect(response).to redirect_to(
        broken_sales_path(issue_type: "purchase_item_links")
      )
      expect(flash[:alert]).to eq(
        "This issue changed while it was being repaired. Review it and try again"
      )
    end
  end

  describe "POST /broken_sales/import_failures/:import_failure_id/pull" do
    it "queues a Woo pull by store order id" do
      failure = record_failure("77")
      allow(Woo::PullSalesJob).to receive(:perform_later)

      post broken_sales_import_failure_pull_path(failure), params: {return_to: broken_sales_path(issue_type: "import_failures", page: 2)}

      expect(Woo::PullSalesJob).to have_received(:perform_later).with(id: "77", requested_by: admin)
      expect(response).to redirect_to(broken_sales_path(issue_type: "import_failures", page: 2))
      expect(flash[:notice]).to eq("Queued a new pull of order 77 from the store.")
    end

    it "queues a Shopify pull by store order id" do
      failure = record_failure("gid://shopify/Order/5150", store_name: "shopify")
      allow(Shopify::PullSaleJob).to receive(:perform_later)

      post broken_sales_import_failure_pull_path(failure)

      expect(Shopify::PullSaleJob).to have_received(:perform_later).with("gid://shopify/Order/5150", requested_by: admin)
      expect(response).to redirect_to(broken_sales_path(issue_type: "import_failures"))
      expect(flash[:notice]).to eq("Queued a new pull of order 5150 from the store.")
    end

    it "denies non-administrators without queueing a pull" do
      failure = record_failure("77")
      log_out
      sign_in(create(:user, :manager))
      allow(Woo::PullSalesJob).to receive(:perform_later)

      post broken_sales_import_failure_pull_path(failure)

      expect(response).to redirect_to(noop_path)
      expect(Woo::PullSalesJob).not_to have_received(:perform_later)
    end
  end
end
