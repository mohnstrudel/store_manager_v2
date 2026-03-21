# frozen_string_literal: true

require "rails_helper"

RSpec.describe Warehouse::UpdateWorkflow do
  describe ".call" do
    let!(:notification) { create(:notification, name: "Warehouse transition") }
    let(:warehouse) { create(:warehouse, name: "Origin", is_default: false) }
    let(:to_warehouse) { create(:warehouse) }

    it "syncs transitions only when to_warehouse_ids is the only attribute" do
      result = described_class.call(
        warehouse:,
        attributes: {"to_warehouse_ids" => [to_warehouse.id.to_s]},
        transition_ids: [to_warehouse.id.to_s]
      )

      expect(result).to eq(described_class::TRANSITIONS_UPDATED)
      expect(warehouse.from_transitions.where(to_warehouse: to_warehouse)).to exist
    end

    it "updates warehouse attributes and runs after_update callback" do
      callback_ran = false

      result = described_class.call(
        warehouse:,
        attributes: {"name" => "Updated Name"},
        transition_ids: [],
        after_update: -> { callback_ran = true }
      )

      expect(result).to eq(described_class::WAREHOUSE_UPDATED)
      expect(warehouse.reload.name).to eq("Updated Name")
      expect(callback_ran).to be(true)
    end
  end
end

