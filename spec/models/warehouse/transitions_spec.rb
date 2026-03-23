# frozen_string_literal: true

require "rails_helper"

# rubocop:todo RSpec/MultipleExpectations
RSpec.describe Warehouse::Transitions do
  describe "#sync_transitions!" do
    let(:warehouse) { create(:warehouse) }
    let(:to_warehouse_one) { create(:warehouse) }
    let(:to_warehouse_two) { create(:warehouse) }
    let(:obsolete_destination) { create(:warehouse) }

    it "creates transitions for selected destinations" do
      expect {
        warehouse.sync_transitions!([to_warehouse_one.id, to_warehouse_two.id])
      }.to change { warehouse.from_transitions.count }.from(0).to(2)
    end

    it "creates or reuses the warehouse transition notification" do
      warehouse.sync_transitions!([to_warehouse_one.id])
      transition = warehouse.from_transitions.last

      expect(transition.notification.name).to eq("Warehouse transition")
      expect(transition.notification.event_type).to eq("warehouse_changed")
      expect(transition.notification.status).to eq("active")
    end

    it "removes transitions that are no longer selected" do
      warehouse.sync_transitions!([to_warehouse_one.id, obsolete_destination.id])

      expect {
        warehouse.sync_transitions!([to_warehouse_one.id])
      }.to change { warehouse.from_transitions.where(to_warehouse_id: obsolete_destination.id).count }.from(1).to(0)
    end

    it "does nothing when the destination list is blank" do
      expect {
        warehouse.sync_transitions!([])
      }.not_to change(WarehouseTransition, :count)
    end

    it "clears transitions when destination array contains only blank values" do
      warehouse.sync_transitions!([to_warehouse_one.id])

      expect {
        warehouse.sync_transitions!([""])
      }.to change { warehouse.from_transitions.count }.from(1).to(0)
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations
