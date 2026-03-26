# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseItem do
  describe ".move_to_warehouse!" do
    it "moves existing purchase items to the destination warehouse" do # rubocop:todo RSpec/MultipleExpectations
      origin = create(:warehouse)
      destination = create(:warehouse)
      purchase_items = create_list(:purchase_item, 3, warehouse: origin)
      allow(PurchaseItem).to receive(:notify_order_status_change!)

      moved_count = described_class.move_to_warehouse!(
        purchase_item_ids: purchase_items.map(&:id),
        warehouse_id: destination.id
      )

      expect(moved_count).to eq(3)
      purchase_items.each do |purchase_item|
        expect(purchase_item.reload.warehouse_id).to eq(destination.id)
      end
      expect(PurchaseItem).to have_received(:notify_order_status_change!).with(
        purchase_item_ids: purchase_items.map(&:id),
        from_id: origin.id,
        to_id: destination.id
      )
    end

    it "groups notifications by origin warehouse" do
      origin_one = create(:warehouse)
      origin_two = create(:warehouse)
      destination = create(:warehouse)
      items_from_origin_one = create_list(:purchase_item, 2, warehouse: origin_one)
      items_from_origin_two = create_list(:purchase_item, 1, warehouse: origin_two)
      all_items = items_from_origin_one + items_from_origin_two
      allow(PurchaseItem).to receive(:notify_order_status_change!)

      moved_count = described_class.move_to_warehouse!(
        purchase_item_ids: all_items.map(&:id),
        warehouse_id: destination.id
      )

      expect(moved_count).to eq(3)
      expect(PurchaseItem).to have_received(:notify_order_status_change!).with(
        purchase_item_ids: items_from_origin_one.map(&:id),
        from_id: origin_one.id,
        to_id: destination.id
      )
      expect(PurchaseItem).to have_received(:notify_order_status_change!).with(
        purchase_item_ids: items_from_origin_two.map(&:id),
        from_id: origin_two.id,
        to_id: destination.id
      )
    end

    it "ignores missing purchase item ids" do
      destination = create(:warehouse)
      purchase_items = create_list(:purchase_item, 2)

      moved_count = described_class.move_to_warehouse!(
        purchase_item_ids: purchase_items.map(&:id) + [999_999, 888_888],
        warehouse_id: destination.id
      )

      expect(moved_count).to eq(2)
      purchase_items.each do |purchase_item|
        expect(purchase_item.reload.warehouse_id).to eq(destination.id)
      end
    end

    it "returns 0 when nothing is selected" do
      destination = create(:warehouse)

      moved_count = described_class.move_to_warehouse!(
        purchase_item_ids: [],
        warehouse_id: destination.id
      )

      expect(moved_count).to eq(0)
    end
  end

  describe "#move_to_warehouse!" do
    it "updates the warehouse_id" do
      purchase_item = create(:purchase_item)
      destination = create(:warehouse)

      purchase_item.move_to_warehouse!(destination.id)

      expect(purchase_item.reload.warehouse_id).to eq(destination.id)
    end
  end
end
