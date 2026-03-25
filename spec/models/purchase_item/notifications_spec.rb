# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseItem do
  include ActiveJob::TestHelper

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  let(:customer) { create(:customer, email: "test@example.com", first_name: "John", last_name: "Doe") }
  let(:sale) { create(:sale, customer: customer, woo_id: "123") }
  let(:warehouse) { create(:warehouse, name: "Test WH", external_name_en: "Public WH", desc_en: "English description for Test WH", desc_de: "German description for Test WH") }
  let(:to_warehouse) { create(:warehouse, name: "New WH", desc_en: "English description for New WH", desc_de: "German description for New WH") }
  let(:sale_item) { create(:sale_item) }
  let(:purchase_item) { create(:purchase_item, sale: sale, warehouse: warehouse, sale_item: sale_item) }
  let(:notification) { create(:notification, event_type: :warehouse_changed, status: :active) }

  describe ".notify_order_status!" do
    it "sends product purchased email" do
      expect {
        described_class.notify_order_status!(purchase_item_ids: Array(purchase_item.id))
      }.to have_enqueued_mail(NotificationsMailer, :order_status_updated_email)
    end
  end

  describe ".notify_order_status_change!" do
    let!(:transition) do # rubocop:todo RSpec/LetSetup
      create(:warehouse_transition,
        notification: notification,
        from_warehouse: warehouse,
        to_warehouse: to_warehouse)
    end

    it "sends warehouse changed email" do
      expect {
        described_class.notify_order_status_change!(
          purchase_item_ids: Array(purchase_item.id),
          from_id: warehouse.id,
          to_id: to_warehouse.id
        )
      }.to have_enqueued_mail(NotificationsMailer, :order_status_changed_email)
    end

    it "does not send email when warehouses are the same" do
      expect {
        described_class.notify_order_status_change!(
          purchase_item_ids: Array(purchase_item.id),
          from_id: warehouse.id,
          to_id: warehouse.id
        )
      }.not_to have_enqueued_mail(NotificationsMailer, :order_status_changed_email)
    end
  end
end
