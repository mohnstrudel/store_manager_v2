# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseItem::Linking do
  let(:product) { create(:product) }
  let(:variant) { product.base_variant }
  let(:purchase) { create(:purchase, product:, variant:) }
  let(:sale) { create(:sale, status: Sale.active_status_names.first) }
  let(:sale_item) { create(:sale_item, sale:, product:, variant:, qty: 2) }

  describe ".link_exact!" do
    it "locks SaleItems and PurchaseItems in ascending ID order" do
      purchase_items = create_list(:purchase_item, 2, purchase:)
      lock_queries = []
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _started, _finished, _id, payload|
        lock_queries << payload[:sql] if payload[:sql].include?("FOR UPDATE")
      end

      PurchaseItem.link_exact!(
        assignments: purchase_items.reverse.map { |purchase_item| {purchase_item:, sale_item:} }
      )

      expect(lock_queries.grep(/FROM "sale_items"/).first).to include('ORDER BY "sale_items"."id" ASC')
      expect(lock_queries.grep(/FROM "purchase_items"/).first).to include('ORDER BY "purchase_items"."id" ASC')
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    it "rechecks exact Product and Variant identity under lock" do
      purchase_item = create(:purchase_item, purchase:)
      other_variant = create(:variant, :with_version, product:)
      mismatched_sale_item = create(:sale_item, sale:, product:, variant: other_variant)

      expect {
        PurchaseItem.link_exact!(
          assignments: [{purchase_item:, sale_item: mismatched_sale_item}]
        )
      }.to raise_error(PurchaseItem::Linking::IdentityMismatch)

      expect(purchase_item.reload.sale_item_id).to be_nil
    end

    it "does not treat missing Product or Variant identity as an exact match" do
      missing_variant_purchase_item = create(:purchase_item, purchase:)
      missing_variant_sale_item = create(:sale_item, sale:, product:, variant:)
      missing_variant_purchase_item.update_columns(variant_id: nil)
      missing_variant_sale_item.update_columns(variant_id: nil)
      missing_product_purchase_item = create(:purchase_item, purchase:)
      missing_product_sale_item = create(:sale_item, sale:, product:, variant:)
      missing_product_purchase_item.update_columns(product_id: nil)

      expect {
        PurchaseItem.link_exact!(
          assignments: [{
            purchase_item: missing_variant_purchase_item,
            sale_item: missing_variant_sale_item
          }]
        )
      }.to raise_error(PurchaseItem::Linking::IdentityMismatch)
      expect {
        PurchaseItem.link_exact!(
          assignments: [{
            purchase_item: missing_product_purchase_item,
            sale_item: missing_product_sale_item
          }]
        )
      }.to raise_error(PurchaseItem::Linking::IdentityMismatch)

      expect(missing_variant_purchase_item.reload.sale_item_id).to be_nil
      expect(missing_product_purchase_item.reload.sale_item_id).to be_nil
    end

    it "rechecks capacity under lock" do
      linked = create(:purchase_item, purchase:, sale_item:)
      extra = create(:purchase_item, purchase:)
      sale_item.update_column(:qty, 1)

      expect {
        PurchaseItem.link_exact!(assignments: [{purchase_item: extra, sale_item:}])
      }.to raise_error(PurchaseItem::Linking::CapacityExceeded)

      aggregate_failures do
        expect(linked.reload.sale_item_id).to eq(sale_item.id)
        expect(extra.reload.sale_item_id).to be_nil
      end
    end

    it "rejects a stale source link that was not included in the ordered SaleItem locks" do
      source_sale_item = create(:sale_item, sale:, product:, variant:)
      target_sale_item = create(:sale_item, sale:, product:, variant:)
      purchase_item = create(:purchase_item, purchase:)
      stale_purchase_item = PurchaseItem.find(purchase_item.id)
      PurchaseItem.where(id: purchase_item.id).update_all(sale_item_id: source_sale_item.id)

      expect {
        PurchaseItem.link_exact!(
          assignments: [{purchase_item: stale_purchase_item, sale_item: target_sale_item}]
        )
      }.to raise_error(PurchaseItem::Linking::StaleLinkState)

      expect(purchase_item.reload.sale_item_id).to eq(source_sale_item.id)
    end

    it "rolls the entire requested batch back when one link is invalid" do
      valid = create(:purchase_item, purchase:)
      invalid = create(:purchase_item, purchase:)
      other_product = create(:product)
      mismatched_sale_item = create(:sale_item, product: other_product, variant: other_product.base_variant)

      expect {
        PurchaseItem.link_exact!(
          assignments: [
            {purchase_item: valid, sale_item:},
            {purchase_item: invalid, sale_item: mismatched_sale_item}
          ]
        )
      }.to raise_error(PurchaseItem::Linking::IdentityMismatch)

      expect([valid.reload.sale_item_id, invalid.reload.sale_item_id]).to eq([nil, nil])
    end

    it "rejects conflicting targets for separately loaded instances of one PurchaseItem" do
      purchase_item = create(:purchase_item, purchase:)
      other_sale_item = create(:sale_item, sale:, product:, variant:)

      expect {
        PurchaseItem.link_exact!(
          assignments: [
            {purchase_item: PurchaseItem.find(purchase_item.id), sale_item:},
            {purchase_item: PurchaseItem.find(purchase_item.id), sale_item: other_sale_item}
          ]
        )
      }.to raise_error(
        ArgumentError,
        "PurchaseItem #{purchase_item.id} has conflicting link targets"
      )

      expect(purchase_item.reload.sale_item_id).to be_nil
    end

    it "atomically replaces an existing capacity occupant" do
      existing = create(:purchase_item, purchase:, sale_item:)
      replacement = create(:purchase_item, purchase:)
      sale_item.update_column(:qty, 1)

      PurchaseItem.link_exact!(
        assignments: [{purchase_item: replacement, sale_item:}],
        unlink_purchase_items: [existing]
      )

      aggregate_failures do
        expect(existing.reload.sale_item_id).to be_nil
        expect(replacement.reload.sale_item_id).to eq(sale_item.id)
      end
    end

    it "schedules one deduplicated notification after all transactions commit" do
      purchase_item = create(:purchase_item, purchase:)
      callbacks = []
      allow(ActiveRecord).to receive(:after_all_transactions_commit) { |&callback| callbacks << callback }
      allow(PurchaseItem).to receive(:notify_order_status!)

      result = PurchaseItem.link_exact!(
        assignments: [
          {purchase_item:, sale_item:},
          {purchase_item:, sale_item:}
        ]
      )

      aggregate_failures do
        expect(result).to eq([purchase_item.id])
        expect(callbacks.size).to eq(1)
        expect(PurchaseItem).not_to have_received(:notify_order_status!)
      end

      callbacks.first.call

      expect(PurchaseItem).to have_received(:notify_order_status!).once.with(
        purchase_item_ids: [purchase_item.id]
      )
    end

    it "deduplicates separately loaded instances with the same target" do
      purchase_item = create(:purchase_item, purchase:)
      callbacks = []
      allow(ActiveRecord).to receive(:after_all_transactions_commit) { |&callback| callbacks << callback }
      allow(PurchaseItem).to receive(:notify_order_status!)

      result = PurchaseItem.link_exact!(
        assignments: [
          {purchase_item: PurchaseItem.find(purchase_item.id), sale_item:},
          {purchase_item: PurchaseItem.find(purchase_item.id), sale_item:}
        ]
      )

      expect(result).to eq([purchase_item.id])
      expect(callbacks.size).to eq(1)

      callbacks.first.call
      expect(PurchaseItem).to have_received(:notify_order_status!).once.with(
        purchase_item_ids: [purchase_item.id]
      )
    end

    it "treats a repeated existing link as a silent no-op" do
      purchase_item = create(:purchase_item, purchase:, sale_item:)
      allow(ActiveRecord).to receive(:after_all_transactions_commit)

      result = PurchaseItem.link_exact!(
        assignments: [{purchase_item:, sale_item:}]
      )

      aggregate_failures do
        expect(result).to eq([])
        expect(ActiveRecord).not_to have_received(:after_all_transactions_commit)
      end
    end

    it "does not schedule notifications for unlink-only changes" do
      purchase_item = create(:purchase_item, purchase:, sale_item:)
      allow(ActiveRecord).to receive(:after_all_transactions_commit)

      result = PurchaseItem.link_exact!(
        assignments: [],
        unlink_purchase_items: [purchase_item]
      )

      aggregate_failures do
        expect(result).to eq([])
        expect(purchase_item.reload.sale_item_id).to be_nil
        expect(ActiveRecord).not_to have_received(:after_all_transactions_commit)
      end
    end

    it "does not expose a notification suppression argument" do
      expect {
        PurchaseItem.link_exact!(assignments: [], notify: false)
      }.to raise_error(ArgumentError, /unknown keyword: :notify/)
    end
  end
end
