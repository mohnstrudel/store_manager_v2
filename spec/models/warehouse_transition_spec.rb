# frozen_string_literal: true

# == Schema Information
#
# Table name: warehouse_transitions
#
#  id                :bigint           not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  from_warehouse_id :bigint
#  notification_id   :bigint           not null
#  to_warehouse_id   :bigint
#
require "rails_helper"

RSpec.describe WarehouseTransition do
  describe "associations" do
    it "belongs to notification" do
      association = described_class.reflect_on_association(:notification)
      expect(association.macro).to eq(:belongs_to)
    end

    it "belongs to from_warehouse" do # rubocop:todo RSpec/MultipleExpectations
      association = described_class.reflect_on_association(:from_warehouse)
      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:class_name]).to eq("Warehouse")
    end

    it "belongs to to_warehouse" do # rubocop:todo RSpec/MultipleExpectations
      association = described_class.reflect_on_association(:to_warehouse)
      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:class_name]).to eq("Warehouse")
    end
  end

  describe "validations" do
    it "requires notification" do
      transition = build(:warehouse_transition, notification: nil)
      expect(transition).not_to be_valid
    end

    it "requires from and to warehouses" do
      transition = build(:warehouse_transition, from_warehouse: nil, to_warehouse: nil)
      expect(transition).not_to be_valid
    end

    it "validates uniqueness of transition for notification" do
      existing = create(:warehouse_transition)
      duplicate = build(:warehouse_transition,
        notification: existing.notification,
        from_warehouse: existing.from_warehouse,
        to_warehouse: existing.to_warehouse)
      expect(duplicate).not_to be_valid
    end
  end

  # rubocop:todo RSpec/MultipleExpectations
  describe ".with_notification_and_warehouses" do
    it "preloads transition notification and warehouse endpoints" do
      transition = create(:warehouse_transition)
      loaded_transition = described_class.with_notification_and_warehouses.find(transition.id)

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
      found = described_class.active_for_notification(from_id: from_warehouse.id, to_id: to_warehouse.id)

      expect(found).to eq(active_transition)
    end

    it "returns nil when no active transition exists for a route" do
      inactive_transition
      active_transition
      active_transition.destroy!
      found = described_class.active_for_notification(from_id: from_warehouse.id, to_id: to_warehouse.id)

      expect(found).to be_nil
    end
  end
  # rubocop:enable RSpec/MultipleExpectations
end
