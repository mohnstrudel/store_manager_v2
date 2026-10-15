# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseItem do
  include ActiveJob::TestHelper

  let(:customer) { create(:customer, email: "test@example.com", first_name: "John", last_name: "Doe") }
  let(:sale) { create(:sale, customer:, woo_store_id: "123") }
  let(:warehouse) { create(:warehouse, name: "Test WH", external_name_en: "Public WH", desc_en: "English description for Test WH", desc_de: "German description for Test WH") }
  let(:to_warehouse) { create(:warehouse, name: "New WH", external_name_en: "Next WH", container_tracking_number: "CONT-42", courier_tracking_url: "https://courier.example/track") }
  let(:product) { create(:product) }
  let(:purchase) { create(:purchase, product:, variant: product.base_variant) }
  let(:sale_item) { create(:sale_item, sale:, product:, variant: product.base_variant) }
  let(:purchase_item) { create(:purchase_item, purchase:, warehouse:, sale_item:) }
  let(:notification) { create(:notification, event_type: :warehouse_changed, status: :active) }

  def ledger_for(item)
    OutboundEmail.where(purchase_item_id: item.id).order(:id)
  end

  describe ".notify_order_status!" do
    it "snapshots a pending explicit-resend status-updated email and enqueues its delivery" do
      expect {
        described_class.notify_order_status!(purchase_item_ids: [purchase_item.id])
      }.to have_enqueued_job(OutboundEmailDeliveryJob).once

      expect(ledger_for(purchase_item).sole).to have_attributes(
        source: "explicit_resend", mail_kind: "order_status_updated", state: "pending",
        sale_item_id: sale_item.id, warehouse_id: warehouse.id, recipient: "test@example.com",
        customer_id: customer.id,
        recipient_name: "John Doe", product_title: sale_item.title,
        subject: %(HandsomeCake Goodies. We updated your order, new status: "Public WH")
      )
    end

    it "creates a fresh intent on every explicit selection, even when the latest pair already matches" do
      2.times { described_class.notify_order_status!(purchase_item_ids: [purchase_item.id]) }

      expect(ledger_for(purchase_item).pluck(:source)).to eq(%w[explicit_resend explicit_resend])
    end

    it "makes a later relink to the resent pair silent" do
      described_class.notify_order_status!(purchase_item_ids: [purchase_item.id])
      described_class.link_exact!(assignments: [], unlink_purchase_items: [purchase_item.reload])

      expect {
        described_class.link_exact!(assignments: [{purchase_item: purchase_item.reload, sale_item:}])
      }.not_to change(OutboundEmail, :count)
    end

    it "creates nothing for unlinked items or customers without an email" do
      unlinked = create(:purchase_item, warehouse:)
      customer.update!(email: nil)

      expect {
        described_class.notify_order_status!(purchase_item_ids: [unlinked.id, purchase_item.id])
      }.not_to change(OutboundEmail, :count)
    end
  end

  describe ".record_status_change_notifications!" do
    before do
      create(:warehouse_transition, notification:, from_warehouse: warehouse, to_warehouse:)
      purchase_item.update!(warehouse: to_warehouse)
    end

    def record(from: warehouse, to: to_warehouse)
      described_class.record_status_change_notifications!(
        purchase_item_ids: [purchase_item.id], from_id: from.id, to_id: to.id
      )
    end

    it "snapshots one pending status-changed email with destination pair and tracking data" do
      expect { record }.to have_enqueued_job(OutboundEmailDeliveryJob).once

      email = ledger_for(purchase_item).sole
      expect(email).to have_attributes(
        source: "warehouse_move", mail_kind: "order_status_changed", state: "pending",
        sale_item_id: sale_item.id, warehouse_id: to_warehouse.id, recipient: "test@example.com",
        subject: %(HandsomeCake Goodies. We updated your order, new status: "Next WH", previous status: "Public WH")
      )
      expect(email.body).to include("CONT-42", "https://courier.example/track")
    end

    it "creates nothing when the warehouses are the same" do
      expect { record(from: to_warehouse) }.not_to change(OutboundEmail, :count)
    end

    it "creates nothing without an active transition" do
      notification.update!(status: :disabled)

      expect { record }.not_to change(OutboundEmail, :count)
    end

    it "creates nothing for customers without an email" do
      customer.update!(email: nil)

      expect { record }.not_to change(OutboundEmail, :count)
    end

    it "makes a later relink to the notified pair silent" do
      record
      described_class.link_exact!(assignments: [], unlink_purchase_items: [purchase_item.reload])

      expect {
        described_class.link_exact!(assignments: [{purchase_item: purchase_item.reload, sale_item:}])
      }.not_to change(OutboundEmail, :count)
    end
  end
end
