# frozen_string_literal: true

require "rails_helper"

RSpec.describe Variant::AssignmentRepair do
  let(:integrity) { Variant::AssignmentIntegrity.new }

  describe ".repair_purchase!" do
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
      allow(PurchaseItem).to receive(:notify_order_status!)
      lock_queries = capture_lock_queries do
        expect(
          described_class.repair_purchase!(
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
        expect(PurchaseItem).not_to have_received(:notify_order_status!)
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
        described_class.repair_purchase!(
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
        described_class.repair_purchase!(
          purchase_id: purchase.id,
          variant_id: product.base_variant.id
        )
      ).to eq(:noop)
    end
  end

  describe ".repair_sale_item!" do
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
      allow(PurchaseItem).to receive(:notify_order_status!)

      lock_queries = capture_lock_queries do
        expect(
          described_class.repair_sale_item!(
            sale_item_id: sale_item.id,
            variant_id: repaired_variant.id
          )
        ).to eq(:repaired)
      end

      aggregate_failures do
        expect(sale_item.reload.variant_id).to eq(repaired_variant.id)
        expect(old_purchase_item.reload.sale_item_id).to be_nil
        expect(exact_purchase_item.reload.sale_item_id).to eq(sale_item.id)
        expect(PurchaseItem).not_to have_received(:notify_order_status!)
        expect(lock_queries.grep(/FROM "sale_items"/)).to include(
          a_string_including('ORDER BY "sale_items"."id" ASC')
        )
        expect(lock_queries.grep(/FROM "purchase_items"/).first).to include(
          'ORDER BY "purchase_items"."id" ASC'
        )
      end
    end
  end

  describe ".repair_purchase_item_link!" do
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
      allow(PurchaseItem).to receive(:notify_order_status!)

      lock_queries = capture_lock_queries do
        expect(
          described_class.repair_purchase_item_link!(
            purchase_item_id: mismatched_purchase_item.id
          )
        ).to eq(:repaired)
      end

      aggregate_failures do
        expect(mismatched_purchase_item.reload.sale_item_id).to be_nil
        expect(exact_purchase_item.reload.sale_item_id).to eq(sale_item.id)
        expect(PurchaseItem).not_to have_received(:notify_order_status!)
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

      described_class.repair_purchase_item_link!(purchase_item_id: mismatch.id)

      expect(mismatch.reload.sale_item_id).to be_nil
      expect(sale_item.reload.purchase_items_count).to eq(0)
    end

    it "treats an already-resolved link as a successful no-op" do
      product = create(:product)
      purchase = create(:purchase, product:)
      sale_item = create(:sale_item, product:)
      purchase_item = create(:purchase_item, purchase:, sale_item:)

      expect(
        described_class.repair_purchase_item_link!(purchase_item_id: purchase_item.id)
      ).to eq(:noop)
    end
  end

  describe ".repair_purchase_item_identity!" do
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
      allow(PurchaseItem).to receive(:notify_order_status!)

      expect(
        described_class.repair_purchase_item_identity!(
          purchase_item_id: purchase_item.id
        )
      ).to eq(:repaired)

      aggregate_failures do
        expect(purchase_item.reload).to have_attributes(
          product_id: purchase.product_id,
          variant_id: purchase.variant_id,
          sale_item_id: exact_sale_item.id
        )
        expect(PurchaseItem).not_to have_received(:notify_order_status!)
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
        described_class.repair_purchase_item_identity!(
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

  describe ".reconcile_duplicate_shopify_identity!" do
    it "locks affected parents before Product and Variant records" do
      stale_product = create(:product)
      canonical_product = create(:product)
      stale_variant = create(:variant, :with_version, product: stale_product)
      canonical_variant = create(:variant, :with_color, product: canonical_product)
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
        described_class.reconcile_duplicate_shopify_identity!(
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
      stale_variant = create(:variant)
      canonical_variant = create(:variant)
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
        described_class.reconcile_duplicate_shopify_identity!(
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
      stale_variant = create(:variant, :with_version, product: stale_product)
      canonical_variant = create(:variant, :with_color, product: canonical_product)
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
      allow(repair).to receive(:repair_sale_item!).and_raise("dependent failure")

      expect {
        repair.reconcile_duplicate_shopify_identity!(
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
