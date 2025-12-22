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
end
