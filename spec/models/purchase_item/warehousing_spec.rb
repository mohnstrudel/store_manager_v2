# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseItem do
  describe ".move_to_warehouse!" do
    include ActiveJob::TestHelper

    let(:origin) { create(:warehouse, external_name_en: "Origin") }
    let(:destination) { create(:warehouse, external_name_en: "Destination") }
    let(:notification) { create(:notification, event_type: :warehouse_changed, status: :active) }

    def linked_item(warehouse: origin, customer: create(:customer, email: "buyer@example.com"))
      product = create(:product)
      sale_item = create(:sale_item, sale: create(:sale, customer:), product:, variant: product.base_variant)
      create(:purchase_item, purchase: create(:purchase, product:, variant: product.base_variant), warehouse:, sale_item:)
    end

    def move(items, to: destination)
      described_class.move_to_warehouse!(purchase_item_ids: items.map(&:id), warehouse_id: to.id)
    end

    def ledger_for(item)
      OutboundEmail.where(purchase_item_id: item.id).order(:id)
    end

    it "moves existing purchase items to the destination warehouse" do
      purchase_items = create_list(:purchase_item, 3, warehouse: origin)

      expect(move(purchase_items)).to eq(3)

      expect(purchase_items.map { |purchase_item| purchase_item.reload.warehouse_id }).to all(eq(destination.id))
    end

    it "creates one pending status-changed intent for a linked item with an active transition" do
      create(:warehouse_transition, notification:, from_warehouse: origin, to_warehouse: destination)
      item = linked_item

      expect { expect(move([item])).to eq(1) }.to have_enqueued_job(OutboundEmailDeliveryJob).once

      expect(ledger_for(item).sole).to have_attributes(
        source: "warehouse_move", mail_kind: "order_status_changed", state: "pending",
        sale_item_id: item.sale_item_id, warehouse_id: destination.id, recipient: "buyer@example.com"
      )
    end

    it "keeps the committed move and pending intent when enqueueing fails" do
      create(:warehouse_transition, notification:, from_warehouse: origin, to_warehouse: destination)
      item = linked_item
      allow(Rails.logger).to receive(:error)
      allow(OutboundEmailDeliveryJob).to receive(:perform_later).and_raise("queue offline")

      expect(move([item])).to eq(1)

      expect(item.reload.warehouse_id).to eq(destination.id)
      expect(ledger_for(item).sole).to be_pending
    end

    it "groups transition lookup by origin warehouse" do
      other_origin = create(:warehouse, external_name_en: "Other origin")
      create(:warehouse_transition, notification:, from_warehouse: origin, to_warehouse: destination)
      notified = linked_item(warehouse: origin)
      not_configured = linked_item(warehouse: other_origin)

      expect(move([notified, not_configured])).to eq(2)

      expect(OutboundEmail.pluck(:purchase_item_id)).to eq([notified.id])
    end

    it "creates no intent without an active transition" do
      create(:warehouse_transition, notification:, from_warehouse: origin, to_warehouse: destination)
      notification.update!(status: :disabled)
      item = linked_item

      expect { move([item]) }.not_to change(OutboundEmail, :count)
    end

    it "creates no intent for an unlinked item with an active transition" do
      create(:warehouse_transition, notification:, from_warehouse: origin, to_warehouse: destination)
      item = create(:purchase_item, warehouse: origin)

      expect { move([item]) }.not_to change(OutboundEmail, :count)
    end

    it "creates no intent without a customer email with an active transition" do
      create(:warehouse_transition, notification:, from_warehouse: origin, to_warehouse: destination)
      item = linked_item(customer: create(:customer, email: nil))

      expect { move([item]) }.not_to change(OutboundEmail, :count)
    end

    it "rolls the warehouse update and the intent back together" do
      create(:warehouse_transition, notification:, from_warehouse: origin, to_warehouse: destination)
      item = linked_item

      expect {
        described_class.transaction do
          move([item])
          raise ActiveRecord::Rollback
        end
      }.not_to have_enqueued_job(OutboundEmailDeliveryJob)

      expect(item.reload.warehouse_id).to eq(origin.id)
      expect(ledger_for(item)).to be_empty
    end

    it "keeps a coherent latest pair so relinking the just-notified pair stays silent" do
      create(:warehouse_transition, notification:, from_warehouse: origin, to_warehouse: destination)
      item = linked_item
      sale_item = item.sale_item
      create(:outbound_email, :assumed_baseline, purchase_item_id: item.id, sale_item_id: sale_item.id, warehouse_id: origin.id)
      move([item])
      described_class.link_exact!(assignments: [], unlink_purchase_items: [item.reload])

      expect {
        described_class.link_exact!(assignments: [{purchase_item: item.reload, sale_item:}])
      }.not_to change(OutboundEmail, :count)
      expect(ledger_for(item).pluck(:source)).to eq(%w[baseline warehouse_move])
    end

    it "ignores missing purchase item ids" do
      purchase_items = create_list(:purchase_item, 2)

      moved_count = described_class.move_to_warehouse!(
        purchase_item_ids: purchase_items.map(&:id) + [999_999, 888_888],
        warehouse_id: destination.id
      )

      expect(moved_count).to eq(2)
      expect(purchase_items.map { |purchase_item| purchase_item.reload.warehouse_id }).to all(eq(destination.id))
    end

    it "returns 0 when nothing is selected" do
      expect(described_class.move_to_warehouse!(purchase_item_ids: [], warehouse_id: destination.id)).to eq(0)
    end
  end

  describe ".ordered_by_current_warehouse_entry" do
    it "keeps warehouse rows ordered by when items entered the current warehouse" do
      warehouse = create(:warehouse)
      first_item = create(:purchase_item, warehouse:, warehouse_arrived_at: 4.minutes.ago)
      second_item = create(:purchase_item, warehouse_arrived_at: 10.minutes.ago)

      second_item.move_to_warehouse!(warehouse.id)
      first_item.update!(shipping_company: create(:shipping_company), tracking_number: "TRACK-1")

      expect(warehouse.purchase_items.ordered_by_current_warehouse_entry).to eq(
        [second_item, first_item]
      )
    end
  end

  describe "#move_to_warehouse!" do
    it "updates the warehouse_id" do
      purchase_item = create(:purchase_item)
      destination = create(:warehouse)

      purchase_item.move_to_warehouse!(destination.id)

      expect(purchase_item.reload.warehouse_id).to eq(destination.id)
    end

    it "stays silent even for a linked item with an active transition" do
      origin = create(:warehouse)
      destination = create(:warehouse)
      notification = create(:notification, event_type: :warehouse_changed, status: :active)
      create(:warehouse_transition, notification:, from_warehouse: origin, to_warehouse: destination)
      purchase_item = create(:purchase_item, warehouse: origin, sale_item: create(:sale_item))

      expect { purchase_item.move_to_warehouse!(destination.id) }.not_to change(OutboundEmail, :count)
    end

    it "refreshes the warehouse arrival timestamp" do
      purchase_item = create(:purchase_item, warehouse_arrived_at: 1.day.ago)
      destination = create(:warehouse)

      expect {
        purchase_item.move_to_warehouse!(destination.id)
      }.to change { purchase_item.reload.warehouse_arrived_at }
    end
  end

  describe "#current_warehouse_arrived_at" do
    it "uses the latest movement into the current warehouse from audit history" do
      origin = create(:warehouse)
      destination = create(:warehouse)
      purchase_item = create(:purchase_item, warehouse: origin)

      purchase_item.audits.last.update!(created_at: 3.days.ago)
      purchase_item.move_to_warehouse!(destination.id)
      purchase_item.audits.last.update!(created_at: 2.days.ago)
      purchase_item.move_to_warehouse!(origin.id)
      purchase_item.audits.last.update!(created_at: 1.day.ago)

      expect(purchase_item.reload.current_warehouse_arrived_at.to_i).to eq(1.day.ago.to_i)
    end
  end
end
