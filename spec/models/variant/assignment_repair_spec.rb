# frozen_string_literal: true

require "rails_helper"

RSpec.describe Variant::AssignmentRepair do
  include ActiveJob::TestHelper

  let(:integrity) { Variant::AssignmentIntegrity.new }

  describe ".repair_purchase" do
    it "uses repair candidates and silently reconciles linked inventory under ordered locks" do
      product = create(:product)
      current_variant = create(:variant, :with_version, product:, version_value: "Current")
      historical_variant = create(:variant, :with_color, product:, color_value: "Archive")
      purchase = create(:purchase, product:, variant: current_variant)
      current_sale_item = create(:sale_item, product:, variant: current_variant)
      historical_sale_item = create(:sale_item, product:, variant: historical_variant)
      purchase_item = create(:purchase_item, purchase:, sale_item: current_sale_item)
      historical_variant.update!(deactivated_at: Time.current)
      purchase.update_columns(variant_id: nil)
      lock_queries = capture_lock_queries do
        expect(
          described_class.repair_purchase(
            purchase_id: purchase.id,
            variant_id: historical_variant.id
          )
        ).to eq(:repaired)
      end

      aggregate_failures do
        expect(purchase.reload.variant_id).to eq(historical_variant.id)
        expect(purchase_item.reload).to have_attributes(
          product_id: product.id,
          variant_id: historical_variant.id,
          sale_item_id: historical_sale_item.id
        )
        expect(OutboundEmail).not_to exist
        expect(lock_queries.grep(/FROM "sale_items"/)).to include(
          a_string_including('ORDER BY "sale_items"."id" ASC')
        )
        expect(lock_queries.grep(/FROM "purchase_items"/).first).to include(
          'ORDER BY "purchase_items"."id" ASC'
        )
      end
    end

    it "rejects a Variant outside Product repair candidates" do
      product = create(:product)
      purchase = create(:purchase, product:)
      purchase.update_columns(variant_id: nil)
      other_variant = create(:product).base_variant

      expect {
        described_class.repair_purchase(
          purchase_id: purchase.id,
          variant_id: other_variant.id
        )
      }.to raise_error(described_class::InvalidCandidate)

      expect(purchase.reload.variant_id).to be_nil
    end

    it "treats an already-resolved Purchase as a successful no-op" do
      product = create(:product)
      purchase = create(:purchase, product:)

      expect(
        described_class.repair_purchase(
          purchase_id: purchase.id,
          variant_id: product.base_variant.id
        )
      ).to eq(:noop)
    end
  end

  describe ".repair_sale_item" do
    it "silently replaces incompatible inventory with exact available inventory" do
      product = create(:product)
      current_variant = create(:variant, :with_version, product:, version_value: "Current")
      repaired_variant = create(:variant, :with_color, product:, color_value: "Repair")
      current_purchase = create(:purchase, product:, variant: current_variant)
      repaired_purchase = create(:purchase, product:, variant: repaired_variant)
      sale_item = create(:sale_item, product:, variant: current_variant)
      old_purchase_item = create(:purchase_item, purchase: current_purchase, sale_item:)
      exact_purchase_item = create(:purchase_item, purchase: repaired_purchase)
      sale_item.update_columns(variant_id: nil)

      lock_queries = capture_lock_queries do
        expect(
          described_class.repair_sale_item(
            sale_item_id: sale_item.id,
            variant_id: repaired_variant.id
          )
        ).to eq(:repaired)
      end

      aggregate_failures do
        expect(sale_item.reload.variant_id).to eq(repaired_variant.id)
        expect(old_purchase_item.reload.sale_item_id).to be_nil
        expect(exact_purchase_item.reload.sale_item_id).to eq(sale_item.id)
        expect(OutboundEmail).not_to exist
        expect(lock_queries.grep(/FROM "sale_items"/)).to include(
          a_string_including('ORDER BY "sale_items"."id" ASC')
        )
        expect(lock_queries.grep(/FROM "purchase_items"/).first).to include(
          'ORDER BY "purchase_items"."id" ASC'
        )
      end
    end

    it "audits the identity change on the SaleItem's Sale without a Slack notification" do
      allow(Rails.env).to receive_messages(production?: true, staging?: false)
      product = create(:product)
      sale_item = create(:sale_item, product:)
      sale_item.update_columns(variant_id: nil)
      variant = create(:variant, :with_color, product:, color_value: "Repair")

      expect {
        described_class.repair_sale_item(sale_item_id: sale_item.id, variant_id: variant.id)
      }.not_to have_enqueued_job(NotifyAboutRecordChanges)

      expect(sale_item.audits.last).to have_attributes(
        action: "update",
        version: 2,
        audited_changes: {"variant_id" => [nil, variant.id]},
        associated: sale_item.sale
      )
    end

    it "audits a Product change together with the Variant change" do
      product = create(:product)
      other_product = create(:product)
      sale_item = create(:sale_item, product: other_product)
      sale_item.update_columns(variant_id: nil)

      described_class.repair_sale_item(sale_item_id: sale_item.id, variant_id: product.base_variant.id, product_id: product.id)

      expect(sale_item.audits.last.audited_changes).to eq(
        "product_id" => [other_product.id, product.id],
        "variant_id" => [nil, product.base_variant.id]
      )
    end

    it "writes no audit for a no-op" do
      sale_item = create(:sale_item)

      expect {
        described_class.repair_sale_item(sale_item_id: sale_item.id, variant_id: sale_item.variant_id)
      }.not_to change(Audited.audit_class, :count)
    end

    it "attributes the audit to the acting user and request" do
      user = create(:user)
      product = create(:product)
      sale_item = create(:sale_item, product:)
      sale_item.update_columns(variant_id: nil)

      Audited.audit_class.as_user(user) do
        described_class.repair_sale_item(sale_item_id: sale_item.id, variant_id: product.base_variant.id)
      end

      expect(sale_item.audits.last).to have_attributes(user:, request_uuid: be_present)
    end
  end

  describe ".repair_sale_item_and_requeue_import" do
    include ActiveJob::TestHelper

    let(:user) { create(:user) }
    let(:product) { create(:product) }
    let(:red) { create(:variant, :with_color, product:, color_value: "Red") }

    def broken_line(**attributes)
      create(:sale_item, product:, variant: red, **attributes).tap do |line|
        line.update_columns(variant_id: nil)
      end
    end

    it "reports what the repair unblocked, using the state before the repair" do
      line = broken_line(qty: 2)

      result = described_class.repair_sale_item_and_requeue_import(sale_item_id: line.id, variant_id: red.id)

      expect(result).to have_attributes(status: :repaired, sale_item: line, queued_pulls: 0)
      expect(result).not_to be_noop
      expect(result.unblocked_consequences).to include({kind: :units_not_reserved, units: 2}, {kind: :debt_miscounted})
      expect(line.reload.variant_id).to eq(red.id)
      expect(result.sale_item.title).to eq("#{product.full_title} → #{red.title}")
    end

    it "queues one pull of the order for the requester after the repair when the order has an unresolved import failure" do
      sale = create(:sale, shopify_id: nil, woo_store_id: "88")
      line = broken_line(sale:)
      Sale::ImportFailure.record(store_name: "woo", store_order_id: "88", message: "boom", sentry_event_id: nil, failed_at: 1.hour.ago)

      result = described_class.repair_sale_item_and_requeue_import(sale_item_id: line.id, variant_id: red.id, requested_by: user)

      expect(result.queued_pulls).to eq(1)
      expect(Woo::PullSalesJob).to have_been_enqueued.with(id: "88", requested_by: user).once
    end

    it "queues nothing for an order without an unresolved import failure" do
      line = broken_line

      result = described_class.repair_sale_item_and_requeue_import(sale_item_id: line.id, variant_id: red.id, requested_by: user)

      expect(result.queued_pulls).to eq(0)
      expect(enqueued_jobs).to be_empty
    end

    it "reports a no-op without consequences or pulls" do
      sale = create(:sale, shopify_id: nil, woo_store_id: "88")
      fixed = create(:sale_item, sale:, product:, variant: red)
      Sale::ImportFailure.record(store_name: "woo", store_order_id: "88", message: "boom", sentry_event_id: nil, failed_at: 1.hour.ago)

      result = described_class.repair_sale_item_and_requeue_import(sale_item_id: fixed.id, variant_id: red.id, requested_by: user)

      expect(result).to be_noop
      expect(result).to have_attributes(status: :noop, unblocked_consequences: [], queued_pulls: 0)
      expect(enqueued_jobs).to be_empty
    end

    it "rejects a Variant outside the Product's repair candidates" do
      line = broken_line

      expect {
        described_class.repair_sale_item_and_requeue_import(sale_item_id: line.id, variant_id: create(:product).base_variant.id)
      }.to raise_error(described_class::InvalidCandidate)
    end
  end

  describe ".repair_purchase_item_link" do
    it "silently unlinks a mismatch and fills capacity with exact available inventory" do
      original_product = create(:product)
      exact_product = create(:product)
      original_purchase = create(:purchase, product: original_product)
      exact_purchase = create(:purchase, product: exact_product)
      sale_item = create(:sale_item, product: original_product, qty: 1)
      mismatched_purchase_item = create(
        :purchase_item,
        purchase: original_purchase,
        sale_item:
      )
      exact_purchase_item = create(:purchase_item, purchase: exact_purchase)
      sale_item.update_columns(
        product_id: exact_product.id,
        variant_id: exact_product.base_variant.id
      )

      lock_queries = capture_lock_queries do
        expect(
          described_class.repair_purchase_item_link(
            purchase_item_id: mismatched_purchase_item.id
          )
        ).to eq(:repaired)
      end

      aggregate_failures do
        expect(mismatched_purchase_item.reload.sale_item_id).to be_nil
        expect(exact_purchase_item.reload.sale_item_id).to eq(sale_item.id)
        expect(OutboundEmail).not_to exist
        expect(integrity.incompatible_purchase_item_link?(mismatched_purchase_item.id)).to be(
          false
        )
        expect(lock_queries.grep(/FROM "sale_items"/).first).to include(
          'ORDER BY "sale_items"."id" ASC'
        )
        expect(lock_queries.grep(/FROM "purchase_items"/).first).to include(
          'ORDER BY "purchase_items"."id" ASC'
        )
      end
    end

    it "unlinks without replacement when the SaleItem has no capacity" do
      original_product = create(:product)
      target_product = create(:product)
      purchase = create(:purchase, product: original_product)
      sale_item = create(:sale_item, product: original_product, qty: 0)
      mismatch = create(:purchase_item, purchase:, sale_item:)
      create(:purchase_item, purchase: create(:purchase, product: target_product))
      sale_item.update_columns(
        product_id: target_product.id,
        variant_id: target_product.base_variant.id
      )

      described_class.repair_purchase_item_link(purchase_item_id: mismatch.id)

      expect(mismatch.reload.sale_item_id).to be_nil
      expect(sale_item.reload.purchase_items_count).to eq(0)
    end

    it "treats an already-resolved link as a successful no-op" do
      product = create(:product)
      purchase = create(:purchase, product:)
      sale_item = create(:sale_item, product:)
      purchase_item = create(:purchase_item, purchase:, sale_item:)

      expect(
        described_class.repair_purchase_item_link(purchase_item_id: purchase_item.id)
      ).to eq(:noop)
    end
  end

  describe ".repair_purchase_item_identity" do
    it "copies Purchase identity and silently reconciles the linked inventory" do
      product = create(:product)
      other_product = create(:product)
      purchase = create(:purchase, product:)
      wrong_sale_item = create(:sale_item, product: other_product)
      exact_sale_item = create(:sale_item, product:)
      purchase_item = create(:purchase_item, purchase:)
      purchase_item.update_columns(
        product_id: other_product.id,
        variant_id: other_product.base_variant.id,
        sale_item_id: wrong_sale_item.id
      )

      expect(
        described_class.repair_purchase_item_identity(
          purchase_item_id: purchase_item.id
        )
      ).to eq(:repaired)

      aggregate_failures do
        expect(purchase_item.reload).to have_attributes(
          product_id: purchase.product_id,
          variant_id: purchase.variant_id,
          sale_item_id: exact_sale_item.id
        )
        expect(OutboundEmail).not_to exist
      end
    end

    it "unlinks unresolved nil identity without relinking to another unresolved row" do
      product = create(:product)
      create(:variant, :with_version, product:)
      create(:variant, :with_color, product:)
      purchase = create(:purchase, product:, variant: product.variants.real.first)
      purchase.update_columns(variant_id: nil)
      other_product = create(:product)
      wrong_sale_item = create(:sale_item, product: other_product)
      unresolved_sale_item = create(
        :sale_item,
        product:,
        variant: product.variants.real.first,
        qty: 1
      )
      unresolved_sale_item.update_columns(variant_id: nil)
      purchase_item = create(
        :purchase_item,
        purchase: create(:purchase, product: other_product),
        sale_item: wrong_sale_item
      )
      purchase_item.update_columns(purchase_id: purchase.id)

      expect(
        described_class.repair_purchase_item_identity(
          purchase_item_id: purchase_item.id
        )
      ).to eq(:repaired)

      aggregate_failures do
        expect(purchase_item.reload).to have_attributes(
          product_id: product.id,
          variant_id: nil,
          sale_item_id: nil
        )
        expect(wrong_sale_item.reload.purchase_items_count).to eq(0)
        expect(unresolved_sale_item.reload.purchase_items).to be_empty
      end
    end
  end

  describe ".reconcile_duplicate_shopify_identity" do
    it "locks affected parents before Product and Variant records" do
      stale_product = create(:product)
      canonical_product = create(:product)
      stale_variant = create(:variant, :synced, :with_version, product: stale_product)
      canonical_variant = create(:variant, :synced, :with_color, product: canonical_product)
      store_id = "gid://shopify/ProductVariant/ordered-locks"
      stale_variant.shopify_info.update!(
        store_id:,
        pull_time: nil,
        ext_created_at: nil,
        ext_updated_at: nil
      )
      canonical_variant.shopify_info.update!(
        store_id:,
        pull_time: 1.day.ago
      )
      purchase = create(
        :purchase,
        product: canonical_product,
        variant: canonical_variant
      )
      sale_item = create(
        :sale_item,
        product: canonical_product,
        variant: canonical_variant
      )
      purchase.update_columns(variant_id: stale_variant.id)
      sale_item.update_columns(variant_id: stale_variant.id)

      lock_queries = capture_lock_queries do
        described_class.reconcile_duplicate_shopify_identity(
          store_id:,
          canonical_store_info_id: canonical_variant.shopify_info.id
        )
      end
      first_lock_index = ->(table) {
        lock_queries.index { |query| query.include?("FROM \"#{table}\"") }
      }
      purchase_lock = first_lock_index.call("purchases")
      sale_item_lock = first_lock_index.call("sale_items")
      product_lock = first_lock_index.call("products")
      variant_lock = first_lock_index.call("variants")

      aggregate_failures do
        expect(purchase_lock).to be < product_lock
        expect(sale_item_lock).to be < product_lock
        expect(product_lock).to be < variant_lock
      end
    end

    it "rechecks unique canonical provenance under the duplicate-group lock" do
      stale_variant = create(:variant, :synced)
      canonical_variant = create(:variant, :synced)
      store_id = "gid://shopify/ProductVariant/stale-canonical"
      stale_variant.shopify_info.update!(
        store_id:,
        pull_time: nil,
        ext_created_at: nil,
        ext_updated_at: nil
      )
      canonical_variant.shopify_info.update!(
        store_id:,
        pull_time: 1.day.ago
      )

      expect {
        described_class.reconcile_duplicate_shopify_identity(
          store_id:,
          canonical_store_info_id: stale_variant.shopify_info.id
        )
      }.to raise_error(
        described_class::InvalidCandidate,
        "Canonical Shopify StoreInfo changed before reconciliation"
      )

      expect(
        StoreInfo.shopify.where(
          storable_type: "Variant",
          store_id:
        ).count
      ).to eq(2)
    end

    it "rolls back the whole external-id reconciliation when a dependent repair fails" do
      stale_product = create(:product)
      canonical_product = create(:product)
      stale_variant = create(:variant, :synced, :with_version, product: stale_product)
      canonical_variant = create(:variant, :synced, :with_color, product: canonical_product)
      store_id = "gid://shopify/ProductVariant/atomic-rollback"
      stale_variant.shopify_info.update!(
        store_id:,
        pull_time: nil,
        ext_created_at: nil,
        ext_updated_at: nil
      )
      canonical_variant.shopify_info.update!(
        store_id:,
        pull_time: 1.day.ago
      )
      purchase = create(
        :purchase,
        product: canonical_product,
        variant: canonical_variant
      )
      sale_item = create(
        :sale_item,
        product: canonical_product,
        variant: canonical_variant
      )
      purchase.update_columns(variant_id: stale_variant.id)
      sale_item.update_columns(variant_id: stale_variant.id)
      repair = described_class.new
      allow(repair).to receive(:repair_sale_item).and_raise("dependent failure")

      expect {
        repair.reconcile_duplicate_shopify_identity(
          store_id:,
          canonical_store_info_id: canonical_variant.shopify_info.id
        )
      }.to raise_error("dependent failure")

      aggregate_failures do
        expect(purchase.reload.variant_id).to eq(stale_variant.id)
        expect(sale_item.reload.variant_id).to eq(stale_variant.id)
        expect(
          StoreInfo.shopify.where(
            storable_type: "Variant",
            store_id:
          ).count
        ).to eq(2)
      end
    end
  end

  describe "#repair_closed_sale_items" do
    subject(:repair) { described_class.new }

    let(:product) { create(:product) }
    let(:variant) { create(:variant, :with_color, product:, color_value: "Repair") }

    def broken_line(status:, line_product: product)
      create(:sale_item, sale: create(:sale, status:), product: line_product).tap do |line|
        line.update_columns(variant_id: nil)
      end
    end

    it "assigns the Variant only to closed orders of the Product" do
      cancelled = broken_line(status: "cancelled")
      trashed = broken_line(status: "trash")
      active = broken_line(status: "processing")
      completed = broken_line(status: "completed")
      other_product = broken_line(status: "refunded", line_product: create(:product))

      result = repair.repair_closed_sale_items(product_id: product.id, variant_id: variant.id)

      expect(result).to have_attributes(repaired: 2, skipped: 0, failed: 0)
      expect([cancelled, trashed].map { |line| line.reload.variant_id }).to all(eq(variant.id))
      expect([active, completed, other_product].map { |line| line.reload.variant_id }).to all(be_nil)
    end

    it "skips and counts lines with linked purchases" do
      linked = broken_line(status: "refunded")
      unlinked = broken_line(status: "refunded")
      purchase_item = create(:purchase_item, purchase: create(:purchase, product:, variant:))
      purchase_item.update_columns(sale_item_id: linked.id)

      result = repair.repair_closed_sale_items(product_id: product.id, variant_id: variant.id)

      expect(result).to have_attributes(repaired: 1, skipped: 1, failed: 0, repaired_sale_ids: [unlinked.sale_id])
      expect(linked.reload.variant_id).to be_nil
      expect(unlinked.reload.variant_id).to eq(variant.id)
      expect(purchase_item.reload.sale_item_id).to eq(linked.id)
    end

    it "changes nothing and counts every closed line as failed when the repair raises" do
      first = broken_line(status: "cancelled")
      second = broken_line(status: "refunded")
      broken_line(status: "processing")
      allow(Audited.audit_class).to receive(:insert_all!).and_raise(ActiveRecord::Deadlocked)
      allow(Sentry).to receive(:capture_exception)

      result = repair.repair_closed_sale_items(product_id: product.id, variant_id: variant.id)

      expect(result).to have_attributes(repaired: 0, skipped: 0, failed: 2, repaired_sale_ids: [], queued_pulls: 0)
      expect([first, second].map { |line| line.reload.variant_id }).to all(be_nil)
      expect(Sentry).to have_received(:capture_exception)
        .with(an_instance_of(ActiveRecord::Deadlocked), extra: {product_id: product.id, variant_id: variant.id})
    end

    it "writes an audit of the Variant change without a Slack notification" do
      allow(Rails.env).to receive_messages(production?: true, staging?: false)
      line = broken_line(status: "cancelled")
      variant_id = variant.id

      expect {
        repair.repair_closed_sale_items(product_id: product.id, variant_id:)
      }.not_to have_enqueued_job(NotifyAboutRecordChanges)

      expect(line.audits.last).to have_attributes(
        action: "update",
        audited_changes: {"variant_id" => [nil, variant_id]},
        associated: line.sale
      )
    end

    it "audits every repaired line after its existing audits, attributed to the acting user" do
      user = create(:user)
      lines = Array.new(2) { broken_line(status: "cancelled") }
      untouched = broken_line(status: "processing")
      lines.first.update_columns(variant_id: product.base_variant.id)
      lines.first.update!(price: 10)
      lines.first.update_columns(variant_id: nil)
      variant_id = variant.id

      Audited.audit_class.as_user(user) { repair.repair_closed_sale_items(product_id: product.id, variant_id:) }

      expect(lines.map { |line| line.audits.reload.pluck(:version) }).to eq([[1, 2, 3], [1, 2]])
      expect(lines.map { |line| line.audits.last }).to all(
        have_attributes(
          action: "update",
          audited_changes: {"variant_id" => [nil, variant_id]},
          user:,
          request_uuid: be_present,
          associated: be_a(Sale)
        )
      )
      expect(untouched.audits.count).to eq(1)
    end

    it "uses the same number of queries however many lines it repairs" do
      count_queries = lambda do
        queries = 0
        subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _started, _finished, _id, payload|
          queries += 1 unless payload[:cached] || %w[SCHEMA TRANSACTION].include?(payload[:name])
        end
        begin
          repair.repair_closed_sale_items(product_id: product.id, variant_id: variant.id)
        ensure
          ActiveSupport::Notifications.unsubscribe(subscriber)
        end
        queries
      end

      variant_id = variant.id
      broken_line_on_variant = -> { create(:sale_item, sale: create(:sale, status: "cancelled"), product:, variant:).tap { |line| line.update_columns(variant_id: nil) } }
      broken_line_on_variant.call
      one_line = count_queries.call
      Array.new(5) { broken_line_on_variant.call }

      expect(count_queries.call).to eq(one_line)
      expect(SaleItem.where(variant_id:).count).to eq(6)
    end

    it "locks the closed lines in id order before the Product and the Variant" do
      broken_line(status: "cancelled")
      variant_id = variant.id

      lock_queries = capture_lock_queries { repair.repair_closed_sale_items(product_id: product.id, variant_id:) }

      expect(lock_queries.grep(/FROM "sale_items"/).first).to include('ORDER BY "sale_items"."id" ASC', "FOR UPDATE OF sale_items")
      expect(lock_queries.index { |sql| sql.include?('FROM "sale_items"') }).to be < lock_queries.index { |sql| sql.include?('FROM "products"') }
    end

    it "queues one pull per repaired order with an unresolved import failure for the requester" do
      user = create(:user)
      failed_sale = create(:sale, status: "cancelled", shopify_id: nil, woo_store_id: "88")
      2.times { create(:sale_item, sale: failed_sale, product:).update_columns(variant_id: nil) }
      healthy = broken_line(status: "cancelled")
      Sale::ImportFailure.record(store_name: "woo", store_order_id: "88", message: "boom", sentry_event_id: nil, failed_at: 1.hour.ago)

      result = repair.repair_closed_sale_items(product_id: product.id, variant_id: variant.id, requested_by: user)

      expect(result).to have_attributes(repaired: 3, queued_pulls: 1, repaired_sale_ids: contain_exactly(failed_sale.id, healthy.sale_id))
      expect(Woo::PullSalesJob).to have_been_enqueued.with(id: "88", requested_by: user).once
    end

    it "queues no pull for an order whose lines were skipped" do
      sale = create(:sale, status: "refunded", shopify_id: nil, woo_store_id: "88")
      linked = create(:sale_item, sale:, product:).tap { |line| line.update_columns(variant_id: nil) }
      create(:purchase_item, purchase: create(:purchase, product:)).update_columns(sale_item_id: linked.id)
      Sale::ImportFailure.record(store_name: "woo", store_order_id: "88", message: "boom", sentry_event_id: nil, failed_at: 1.hour.ago)

      result = repair.repair_closed_sale_items(product_id: product.id, variant_id: variant.id)

      expect(result).to have_attributes(repaired: 0, skipped: 1, queued_pulls: 0)
      expect(enqueued_jobs).to be_empty
    end

    it "rejects a Variant of another Product before touching any line" do
      line = broken_line(status: "cancelled")

      expect {
        repair.repair_closed_sale_items(product_id: product.id, variant_id: create(:product).base_variant.id)
      }.to raise_error(described_class::InvalidCandidate)

      expect(line.reload.variant_id).to be_nil
    end

    it "rejects a Variant of another Product although no closed line needs repair" do
      expect {
        repair.repair_closed_sale_items(product_id: product.id, variant_id: create(:product).base_variant.id)
      }.to raise_error(described_class::InvalidCandidate)
    end

    it "reassigns a line whose Variant belongs to another Product" do
      line = broken_line(status: "trash")
      line.update_columns(variant_id: create(:product).base_variant.id)

      result = repair.repair_closed_sale_items(product_id: product.id, variant_id: variant.id)

      expect(result).to have_attributes(repaired: 1)
      expect(line.reload.variant_id).to eq(variant.id)
      expect(line.audits.last.audited_changes["variant_id"].last).to eq(variant.id)
    end
  end

  def capture_lock_queries
    lock_queries = []
    subscriber = ActiveSupport::Notifications.subscribe(
      "sql.active_record"
    ) do |_name, _started, _finished, _id, payload|
      lock_queries << payload[:sql] if payload[:sql].include?("FOR UPDATE")
    end
    yield
    lock_queries
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end
end
