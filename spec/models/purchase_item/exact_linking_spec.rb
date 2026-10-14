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

    it "records one deduplicated intent for duplicate assignments" do
      purchase_item = create(:purchase_item, purchase:)

      result = PurchaseItem.link_exact!(
        assignments: [
          {purchase_item:, sale_item:},
          {purchase_item: PurchaseItem.find(purchase_item.id), sale_item:}
        ]
      )

      expect(result).to eq([purchase_item.id])
      expect(OutboundEmail.where(purchase_item_id: purchase_item.id).count).to eq(1)
    end

    it "treats a repeated existing link as a silent no-op" do
      purchase_item = create(:purchase_item, purchase:, sale_item:)

      expect {
        expect(PurchaseItem.link_exact!(assignments: [{purchase_item:, sale_item:}])).to eq([])
      }.not_to change(OutboundEmail, :count)
    end

    it "does not record an intent for unlink-only changes" do
      purchase_item = create(:purchase_item, purchase:, sale_item:)

      expect {
        result = PurchaseItem.link_exact!(assignments: [], unlink_purchase_items: [purchase_item])
        expect(result).to eq([])
      }.not_to change(OutboundEmail, :count)

      expect(purchase_item.reload.sale_item_id).to be_nil
    end

    describe "order-status intents" do
      include ActiveJob::TestHelper

      let(:other_sale_item) { create(:sale_item, sale:, product:, variant:) }

      def link(purchase_item, target)
        PurchaseItem.link_exact!(assignments: [{purchase_item: purchase_item.reload, sale_item: target}])
      end

      def unlink(purchase_item)
        PurchaseItem.link_exact!(assignments: [], unlink_purchase_items: [purchase_item.reload])
      end

      def ledger_for(purchase_item)
        OutboundEmail.where(purchase_item_id: purchase_item.id).order(:id)
      end

      def record_current_pair(purchase_item, state:)
        pair = {
          purchase_item_id: purchase_item.id,
          sale_item_id: purchase_item.sale_item_id,
          warehouse_id: purchase_item.warehouse_id
        }
        case state
        when "assumed_baseline" then create(:outbound_email, :assumed_baseline, **pair)
        when "accepted" then create(:outbound_email, state:, accepted_at: Time.current, **pair)
        else create(:outbound_email, state:, **pair)
        end
      end

      it "snapshots one pending status-updated email for a first eligible link" do
        purchase_item = create(:purchase_item, purchase:)

        expect { link(purchase_item, sale_item) }.to change(OutboundEmail, :count).by(1)

        email = ledger_for(purchase_item).sole
        expect(email).to have_attributes(
          source: "link", mail_kind: "order_status_updated", state: "pending",
          purchase_item_id: purchase_item.id, sale_item_id: sale_item.id,
          warehouse_id: purchase_item.warehouse_id, recipient: sale.customer.email,
          sender: "HandsomeCake Goodies <store@handsomecake.com>",
          subject: %(HandsomeCake Goodies. We updated your order, new status: "#{purchase_item.warehouse.external_name_en}")
        )
        expect(email.body).to include(
          "Hello #{sale.customer.full_name}", sale_item.title, purchase_item.warehouse.external_name_de
        )
      end

      %w[assumed_baseline pending accepted simulated].each do |state|
        it "creates nothing when relinking the same pair after a #{state} latest row" do
          purchase_item = create(:purchase_item, purchase:, sale_item:)
          record_current_pair(purchase_item, state:)
          unlink(purchase_item)

          expect {
            expect { link(purchase_item, sale_item) }.not_to change(OutboundEmail, :count)
          }.not_to have_enqueued_job(OutboundEmailDeliveryJob)
        end
      end

      it "creates a new intent for a different sale item of the same customer" do
        purchase_item = create(:purchase_item, purchase:, sale_item:)
        record_current_pair(purchase_item, state: "assumed_baseline")

        link(purchase_item, other_sale_item)

        expect(ledger_for(purchase_item).last).to have_attributes(
          state: "pending", sale_item_id: other_sale_item.id, recipient: sale.customer.email
        )
      end

      it "creates a new intent for a sale item of another customer" do
        other_customer = create(:customer, email: "someone.else@example.com")
        other_customer_sale_item = create(:sale_item, sale: create(:sale, customer: other_customer), product:, variant:)
        purchase_item = create(:purchase_item, purchase:, sale_item:)
        record_current_pair(purchase_item, state: "assumed_baseline")

        link(purchase_item, other_customer_sale_item)

        expect(ledger_for(purchase_item).last).to have_attributes(
          state: "pending", sale_item_id: other_customer_sale_item.id, recipient: "someone.else@example.com"
        )
      end

      it "creates a new intent when the warehouse differs from the latest pair" do
        purchase_item = create(:purchase_item, purchase:, sale_item:)
        record_current_pair(purchase_item, state: "accepted")
        unlink(purchase_item)
        new_warehouse = create(:warehouse)
        purchase_item.update_columns(warehouse_id: new_warehouse.id)

        link(purchase_item, sale_item)

        expect(ledger_for(purchase_item).last).to have_attributes(
          state: "pending", sale_item_id: sale_item.id, warehouse_id: new_warehouse.id
        )
      end

      it "notifies on both changes of an A to B to A sequence" do
        purchase_item = create(:purchase_item, purchase:)

        [sale_item, other_sale_item, sale_item].each { |target| link(purchase_item, target) }

        expect(ledger_for(purchase_item).pluck(:sale_item_id))
          .to eq([sale_item.id, other_sale_item.id, sale_item.id])
      end

      it "creates nothing and keeps the latest pair when the customer has no email" do
        emailless_sale_item = create(:sale_item, sale: create(:sale, customer: create(:customer, email: nil)), product:, variant:)
        purchase_item = create(:purchase_item, purchase:, sale_item:)
        record_current_pair(purchase_item, state: "assumed_baseline")

        expect {
          link(purchase_item, emailless_sale_item)
          link(purchase_item, sale_item)
        }.not_to change(OutboundEmail, :count)
      end

      it "stays silent on a customer email edit and snapshots the new address on a later changed pair" do
        purchase_item = create(:purchase_item, purchase:)
        original_email = sale.customer.email
        link(purchase_item, sale_item)

        expect { sale.customer.update!(email: "new.address@example.com") }.not_to change(OutboundEmail, :count)

        link(purchase_item, other_sale_item)

        expect(ledger_for(purchase_item).pluck(:recipient)).to eq([original_email, "new.address@example.com"])
      end

      it "leaves no row and no delivery job when the outer transaction rolls back" do
        purchase_item = create(:purchase_item, purchase:)

        expect {
          PurchaseItem.transaction do
            link(purchase_item, sale_item)
            raise ActiveRecord::Rollback
          end
        }.not_to have_enqueued_job(OutboundEmailDeliveryJob)

        expect(ledger_for(purchase_item)).to be_empty
      end

      it "enqueues the delivery job once, only after the outermost commit" do
        purchase_item = create(:purchase_item, purchase:)

        expect {
          PurchaseItem.transaction do
            link(purchase_item, sale_item)
            expect(OutboundEmailDeliveryJob).not_to have_been_enqueued
          end
        }.to have_enqueued_job(OutboundEmailDeliveryJob).once

        expect(OutboundEmailDeliveryJob).to have_been_enqueued.with(ledger_for(purchase_item).sole.id)
      end

      it "keeps the committed link and one pending intent when enqueueing fails" do
        purchase_item = create(:purchase_item, purchase:)
        logged = []
        allow(Rails.logger).to receive(:error) { |message| logged << message }
        allow(OutboundEmailDeliveryJob).to receive(:perform_later).and_raise("queue offline")

        expect(link(purchase_item, sale_item)).to eq([purchase_item.id])

        email = ledger_for(purchase_item).sole
        expect(purchase_item.reload.sale_item_id).to eq(sale_item.id)
        expect(email).to be_pending
        expect(logged.join("\n")).to include("OutboundEmail #{email.id}", "queue offline")

        unlink(purchase_item)
        expect { link(purchase_item, sale_item) }.not_to change(OutboundEmail, :count)
      end
    end

    it "does not expose a notification suppression argument" do
      expect {
        PurchaseItem.link_exact!(assignments: [], notify: false)
      }.to raise_error(ArgumentError, /unknown keyword: :notify/)
    end
  end
end
