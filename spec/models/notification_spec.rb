require "rails_helper"

RSpec.describe Notification do
  include ActiveJob::TestHelper

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  describe "enums" do
    it "defines status enum" do
      expect(described_class.statuses).to eq({"disabled" => 0, "active" => 1})
    end

    it "defines event_type enum" do
      expect(described_class.event_types).to eq({"product_purchased" => 0, "warehouse_changed" => 1})
    end
  end

  describe "associations" do
    it "has many warehouse transitions" do
      association = described_class.reflect_on_association(:warehouse_transitions)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:nullify)
    end
  end

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe ".dispatch" do
    let(:customer) { create(:customer, email: "test@example.com", first_name: "John", last_name: "Doe") }
    let(:sale) { create(:sale, customer: customer, woo_id: "123") }
    let(:warehouse) { create(:warehouse, name: "Test WH", external_name: "Public WH") }
    let(:to_warehouse) { create(:warehouse, name: "New WH") }
    let(:product_sale) { create(:product_sale) }
    let(:purchased_product) { create(:purchased_product, sale: sale, warehouse: warehouse, product_sale: product_sale) }
    let(:notification) { create(:notification, event_type: :warehouse_changed, status: :active) }

    context "when event is product_purchased" do
      it "sends product purchased email" do
        expect {
          described_class.dispatch(
            event: described_class.event_types[:product_purchased],
            context: {purchased_product_id: purchased_product.id}
          )
        }.to have_enqueued_job.on_queue("default")
      end
    end

    context "when event is warehouse_changed" do
      let!(:transition) do
        create(:warehouse_transition,
          notification: notification,
          from_warehouse: warehouse,
          to_warehouse: to_warehouse)
      end

      it "sends warehouse changed email" do
        expect {
          described_class.dispatch(
            event: described_class.event_types[:warehouse_changed],
            context: {
              purchased_product_id: purchased_product.id,
              from_id: warehouse.id,
              to_id: to_warehouse.id
            }
          )
        }.to have_enqueued_job.on_queue("default")
      end
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
