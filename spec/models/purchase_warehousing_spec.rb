# frozen_string_literal: true

require "rails_helper"

RSpec.describe Purchase do
  let(:warehouse) { create(:warehouse) }
  let(:purchase) { create(:purchase, amount: 3) }

  describe "#move_to_warehouse!" do
    it "creates purchase items and links sales when the purchase has no items" do
      allow(purchase).to receive(:link_with_sales)

      moved_count = purchase.move_to_warehouse!(warehouse.id)

      expect(moved_count).to eq(3)
      expect(PurchaseItem.where(purchase_id: purchase.id, warehouse_id: warehouse.id).count).to eq(3)
      expect(purchase).to have_received(:link_with_sales)
    end

    it "relocates existing purchase items to the destination warehouse" do
      origin = create(:warehouse)
      destination = create(:warehouse)
      create(:warehouse_transition, notification: create(:notification, event_type: :warehouse_changed, status: :active), from_warehouse: origin, to_warehouse: destination)
      linked_items = create_list(:purchase_item, 2, purchase:, warehouse: origin, sale_item: create(:sale_item))

      moved_count = purchase.move_to_warehouse!(destination.id)

      expect(moved_count).to eq(2)
      expect(linked_items.map { |item| item.reload.warehouse_id }).to all(eq(destination.id))
      expect(OutboundEmail.where(source: "warehouse_move").pluck(:purchase_item_id)).to match_array(linked_items.map(&:id))
    end

    context "when amount is zero" do
      let(:purchase) { create(:purchase, amount: 0) }

      it "returns 0 without creating purchase items" do
        expect {
          expect(purchase.move_to_warehouse!(warehouse.id)).to eq(0)
        }.not_to change(PurchaseItem, :count)
      end
    end

    context "when warehouse does not exist" do
      let(:invalid_warehouse_id) { 999999 }

      it "raises ActiveRecord::RecordInvalid" do
        expect {
          purchase.move_to_warehouse!(invalid_warehouse_id)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "#link_with_sales" do
    let!(:purchase_item1) { create(:purchase_item, purchase:) } # rubocop:todo RSpec/IndexedLet
    let!(:purchase_item2) { create(:purchase_item, purchase:) } # rubocop:todo RSpec/IndexedLet
    let(:sale_item) { create(:sale_item, qty: 2, product: purchase.product) }

    before do
      allow(SaleItem).to receive(:linkable_for).with(purchase).and_return([sale_item])
    end

    it "links purchase with sales" do
      # rubocop:todo RSpec/StubbedMock
      # rubocop:todo RSpec/MessageSpies
      expect(purchase).to receive(:link_purchase_items).and_return([purchase_item1.id, purchase_item2.id])
      # rubocop:enable RSpec/MessageSpies
      # rubocop:enable RSpec/StubbedMock

      purchase.link_with_sales
    end

    it "does nothing when purchase has no purchase_items" do
      purchase.purchase_items.destroy_all
      allow(purchase).to receive(:link_purchase_items).and_return([])

      expect { purchase.link_with_sales }.not_to change(OutboundEmail, :count)
    end
  end
end
