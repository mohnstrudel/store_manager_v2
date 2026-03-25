# frozen_string_literal: true

require "rails_helper"

RSpec.describe Warehouse do
  describe "#create_from_form!" do
    let!(:existing_default) { create(:warehouse, :default) }
    let(:warehouse) { described_class.new }

    it "creates the warehouse, runs the block, and preserves a single default" do
      callback_ran = false

      warehouse.create_from_form!(name: "New Default", is_default: true) do |_created_warehouse|
        callback_ran = true
      end

      aggregate_failures do
        expect(warehouse).to be_persisted
        expect(callback_ran).to be(true)
        expect(warehouse.reload.is_default).to be(true)
        expect(existing_default.reload.is_default).to be(false)
      end
    end
  end

  describe "#apply_form_changes!" do
    let(:warehouse) { create(:warehouse) }
    let!(:notification) { create(:notification, name: "Warehouse transition") }

    it "syncs transitions only when transition ids are the only update" do
      destination = create(:warehouse)

      result = warehouse.apply_form_changes!(
        attributes: {"to_warehouse_ids" => [destination.id.to_s]},
        transition_ids: [destination.id.to_s]
      )

      aggregate_failures do
        expect(result).to eq(Warehouse::Editing::TRANSITIONS_UPDATED)
        expect(warehouse.from_transitions.where(to_warehouse: destination)).to exist
      end
    end

    it "updates attributes, runs the callback, and syncs transitions" do
      destination = create(:warehouse)
      callback_ran = false

      result = warehouse.apply_form_changes!(
        attributes: {"name" => "Updated Name"},
        transition_ids: [destination.id.to_s],
        after_update: -> { callback_ran = true }
      )

      aggregate_failures do
        expect(result).to eq(Warehouse::Editing::WAREHOUSE_UPDATED)
        expect(warehouse.reload.name).to eq("Updated Name")
        expect(callback_ran).to be(true)
        expect(warehouse.from_transitions.where(to_warehouse: destination)).to exist
      end
    end
  end

  describe "#update_position!" do
    let!(:warehouse_one) { create(:warehouse, position: 1) }
    let(:warehouse) { create(:warehouse, position: 2) }
    let!(:warehouse_three) { create(:warehouse, position: 3) }

    it "updates the warehouse position within the ordered list" do
      warehouse.update_position!(1)

      aggregate_failures do
        expect(warehouse.reload.position).to eq(1)
        expect(warehouse_one.reload.position).to eq(2)
        expect(warehouse_three.reload.position).to eq(3)
      end
    end
  end
end
