# frozen_string_literal: true

require "rails_helper"

# rubocop:todo RSpec/MultipleExpectations
RSpec.describe WarehouseTransition::Lookup do
  describe ".for_notification_lookup" do
    it "preloads transition notification and warehouse endpoints" do
      transition = create(:warehouse_transition)
      loaded_transition = WarehouseTransition.for_notification_lookup.find(transition.id)

      expect(loaded_transition.association(:notification)).to be_loaded
      expect(loaded_transition.association(:from_warehouse)).to be_loaded
      expect(loaded_transition.association(:to_warehouse)).to be_loaded
    end
  end

  describe ".active_for_notification" do
    let(:from_warehouse) { create(:warehouse) }
    let(:to_warehouse) { create(:warehouse) }
    let(:inactive_notification) { create(:notification, status: :disabled) }
    let(:active_notification) { create(:notification, status: :active) }
    let(:inactive_transition) { create(:warehouse_transition, from_warehouse:, to_warehouse:, notification: inactive_notification) }
    let(:active_transition) { create(:warehouse_transition, from_warehouse:, to_warehouse:, notification: active_notification) }

    it "returns transition with active notification for a route" do
      inactive_transition
      active_transition
      found = WarehouseTransition.active_for_notification(from_id: from_warehouse.id, to_id: to_warehouse.id)

      expect(found).to eq(active_transition)
    end

    it "returns nil when no active transition exists for a route" do
      inactive_transition
      active_transition
      active_transition.destroy!
      found = WarehouseTransition.active_for_notification(from_id: from_warehouse.id, to_id: to_warehouse.id)

      expect(found).to be_nil
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations
