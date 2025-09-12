require "rails_helper"

describe PurchasedNotifier do
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

  describe "#handle_product_purchase" do
    it "sends product purchased email" do
      expect {
        described_class.new(purchase_item_ids: Array(purchase_item.id))
          .handle_product_purchase
      }.to have_enqueued_mail(NotificationsMailer, :product_purchased_email)
    end
  end

  describe "#handle_warehouse_change" do
    let!(:transition) do
      create(:warehouse_transition,
        notification: notification,
        from_warehouse: warehouse,
        to_warehouse: to_warehouse)
    end

    it "sends warehouse changed email" do
      expect {
        described_class.new(
          purchase_item_ids: Array(purchase_item.id),
          from_id: warehouse.id,
          to_id: to_warehouse.id
        ).handle_warehouse_change
      }.to have_enqueued_mail(NotificationsMailer, :warehouse_changed_email)
    end

    it "does not send email when warehouses are the same" do
      expect {
        described_class.new(
          purchase_item_ids: Array(purchase_item.id),
          from_id: warehouse.id,
          to_id: warehouse.id
        ).handle_warehouse_change
      }.not_to have_enqueued_mail(NotificationsMailer, :warehouse_changed_email)
    end
  end
end
