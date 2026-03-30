# frozen_string_literal: true

# == Schema Information
#
# Table name: purchase_items
#
#  id                  :bigint           not null, primary key
#  expenses            :decimal(8, 2)
#  height              :integer
#  length              :integer
#  shipping_cost       :decimal(8, 2)    default(0.0), not null
#  tracking_number     :string
#  weight              :integer
#  width               :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  purchase_id         :bigint
#  sale_item_id        :bigint
#  shipping_company_id :bigint
#  warehouse_id        :bigint           not null
#
require "rails_helper"

describe PurchaseItem do
  describe "auditing" do
    it "is audited" do
      expect(described_class.auditing_enabled).to be true
    end
  end

  describe "#warehouse_movements" do
    it "returns warehouse history from audits" do
      first_warehouse = create(:warehouse, name: "First Warehouse")
      second_warehouse = create(:warehouse, name: "Second Warehouse")
      third_warehouse = create(:warehouse, name: "Third Warehouse")
      purchase_item = create(:purchase_item, warehouse: first_warehouse)

      purchase_item.move_to_warehouse!(second_warehouse.id)
      purchase_item.move_to_warehouse!(third_warehouse.id)

      expect(
        purchase_item.reload.warehouse_movements.map { |movement| [movement.warehouse&.name, movement.moved_in.to_i] }
      ).to eq([
        ["First Warehouse", purchase_item.audits.first.created_at.to_i],
        ["Second Warehouse", purchase_item.audits.second.created_at.to_i],
        ["Third Warehouse", purchase_item.audits.third.created_at.to_i]
      ])
    end
  end
end
