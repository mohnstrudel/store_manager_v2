require "rails_helper"

describe Notifier do
  include ActiveJob::TestHelper

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  let(:customer) { create(:customer, email: "test@example.com", first_name: "John", last_name: "Doe") }
  let(:sale) { create(:sale, customer: customer, woo_id: "123") }
  let(:warehouse) { create(:warehouse, name: "Test WH", external_name: "Public WH") }
  let(:to_warehouse) { create(:warehouse, name: "New WH") }
  let(:product_sale) { create(:product_sale) }
  let(:purchased_product) { create(:purchased_product, sale: sale, warehouse: warehouse, product_sale: product_sale) }
  let(:notification) { create(:notification, event_type: :warehouse_changed, status: :active) }

  describe "#handle_product_purchase" do
    it "sends product purchased email" do
      expect {
        described_class.new(purchased_product_ids: Array(purchased_product.id))
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
          purchased_product_ids: Array(purchased_product.id),
          from_id: warehouse.id,
          to_id: to_warehouse.id
        ).handle_warehouse_change
      }.to have_enqueued_mail(NotificationsMailer, :warehouse_changed_email)
    end

    it "does not send email when warehouses are the same" do
      expect {
        described_class.new(
          purchased_product_ids: Array(purchased_product.id),
          from_id: warehouse.id,
          to_id: warehouse.id
        ).handle_warehouse_change
      }.not_to have_enqueued_mail(NotificationsMailer, :warehouse_changed_email)
    end
  end
end
