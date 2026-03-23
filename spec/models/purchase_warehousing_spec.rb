# frozen_string_literal: true

require "rails_helper"

RSpec.describe Purchase do
  let(:warehouse) { create(:warehouse) }
  let(:purchase) { create(:purchase, amount: 3) }

  describe "#add_items_to_warehouse" do
    it "creates purchase items for the warehouse" do
      expect {
        purchase.add_items_to_warehouse(warehouse.id)
      }.to change(PurchaseItem, :count).by(3)
    end

    it "associates purchase items with the purchase" do
      purchase.add_items_to_warehouse(warehouse.id)

      expect(PurchaseItem.where(purchase_id: purchase.id).count).to eq(3)
    end

    it "associates purchase items with the warehouse" do
      purchase.add_items_to_warehouse(warehouse.id)

      expect(PurchaseItem.where(warehouse_id: warehouse.id).count).to eq(3)
    end

    it "sets created_at and updated_at timestamps" do
      purchase.add_items_to_warehouse(warehouse.id)
      purchase_items = PurchaseItem.where(purchase_id: purchase.id)

      expect(purchase_items.all? { |item| item.created_at.present? && item.updated_at.present? }).to be true
    end

    context "when amount is zero" do
      let(:purchase) { create(:purchase, amount: 0) }

      it "creates no purchase items" do
        expect {
          purchase.add_items_to_warehouse(warehouse.id)
        }.not_to change(PurchaseItem, :count)
      end
    end

    context "when warehouse does not exist" do
      let(:invalid_warehouse_id) { 999999 }

      it "raises ActiveRecord::RecordInvalid" do
        expect {
          purchase.add_items_to_warehouse(invalid_warehouse_id)
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
      expect(Purchase::Linker).to receive(:link).with(purchase).and_return([purchase_item1.id, purchase_item2.id])
      # rubocop:enable RSpec/MessageSpies
      # rubocop:enable RSpec/StubbedMock
      allow(PurchaseItem::Notifier).to receive(:handle_product_purchase)

      purchase.link_with_sales
    end

    it "sends notifications for linked purchase items" do
      allow(Purchase::Linker).to receive(:link).and_return([purchase_item1.id, purchase_item2.id])
      allow(PurchaseItem::Notifier).to receive(:handle_product_purchase)
      purchase.link_with_sales

      expect(PurchaseItem::Notifier).to have_received(:handle_product_purchase).with(purchase_item_ids: [purchase_item1.id, purchase_item2.id])
    end

    it "does nothing when purchase has no purchase_items" do
      purchase.purchase_items.destroy_all
      allow(Purchase::Linker).to receive(:link).and_return([])
      allow(PurchaseItem::Notifier).to receive(:handle_product_purchase)

      purchase.link_with_sales

      expect(PurchaseItem::Notifier).to have_received(:handle_product_purchase).with(purchase_item_ids: [])
    end
  end
end
