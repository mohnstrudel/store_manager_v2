require "rails_helper"

describe ProductMover do
  let(:purchase) { create(:purchase, amount: 3) }
  let(:from_warehouse) { create(:warehouse) }
  let(:to_warehouse) { create(:warehouse) }
  let(:purchase_items) {
    create_list(:purchase_item, 3, warehouse: from_warehouse, purchase:)
  }

  describe "#move" do
    context "when moving existing purchased products" do
      it "moves all products to the destination warehouse" do
        moved_count = described_class.new(
          warehouse_id: to_warehouse.id,
          purchase_items_ids: purchase_items.map(&:id)
        ).move

        expect(moved_count).to eq(3)

        purchase_items.each do |product|
          expect(product.reload.warehouse_id).to eq(to_warehouse.id)
        end
      end

      it "moves products from multiple warehouses" do
        another_warehouse = create(:warehouse)
        products_from_another = create_list(:purchase_item, 2, warehouse: another_warehouse, purchase:)
        all_products = purchase_items + products_from_another

        moved_count = described_class.new(
          warehouse_id: to_warehouse.id,
          purchase_items_ids: all_products.map(&:id)
        ).move

        expect(moved_count).to eq(5)
        all_products.each do |product|
          expect(product.reload.warehouse_id).to eq(to_warehouse.id)
        end
      end

      it "handles moving products that are already in the destination warehouse" do
        products_already_there = create_list(:purchase_item, 2, warehouse: to_warehouse, purchase:)
        all_products = purchase_items + products_already_there

        moved_count = described_class.new(
          warehouse_id: to_warehouse.id,
          purchase_items_ids: all_products.map(&:id)
        ).move

        expect(moved_count).to eq(5)
        all_products.each do |product|
          expect(product.reload.warehouse_id).to eq(to_warehouse.id)
        end
      end

      it "calls notification for warehouse relocation" do
        notifier_double = instance_double(PurchasedNotifier)
        allow(PurchasedNotifier).to receive(:new).and_return(notifier_double)
        allow(notifier_double).to receive(:handle_warehouse_change)

        described_class.new(
          warehouse_id: to_warehouse.id,
          purchase_items_ids: purchase_items.map(&:id)
        ).move

        expect(PurchasedNotifier).to have_received(:new).with(
          purchase_item_ids: purchase_items.map(&:id),
          from_id: from_warehouse.id,
          to_id: to_warehouse.id
        )
        expect(notifier_double).to have_received(:handle_warehouse_change)
      end
    end

    context "when creating new purchased products from a purchase" do
      let(:purchase_without_products) { create(:purchase, amount: 3) }

      it "creates new purchased products in the destination warehouse" do
        moved_count = described_class.new(
          warehouse_id: to_warehouse.id,
          purchase: purchase_without_products
        ).move

        expect(moved_count).to eq(3)
        expect(to_warehouse.purchase_items.where(purchase: purchase_without_products).count).to eq(3)
      end

      it "calls notification for newly located items" do
        notifier_double = instance_double(PurchasedNotifier)
        allow(PurchasedNotifier).to receive(:new).and_return(notifier_double)
        allow(notifier_double).to receive(:handle_product_purchase)

        described_class.new(
          warehouse_id: to_warehouse.id,
          purchase: purchase_without_products
        ).move

        expect(PurchasedNotifier).to have_received(:new).with(
          purchase_item_ids: match_array(
            to_warehouse.purchase_items.where(purchase: purchase_without_products).pluck(:id)
          )
        )
        expect(notifier_double).to have_received(:handle_product_purchase)
      end

      it "handles purchase with zero amount" do
        zero_purchase = create(:purchase, amount: 0)

        moved_count = described_class.new(
          warehouse_id: to_warehouse.id,
          purchase: zero_purchase
        ).move

        expect(moved_count).to eq(0)
        expect(to_warehouse.purchase_items.where(purchase: zero_purchase).count).to eq(0)
      end
    end

    context "when no products or purchase are provided" do
      it "returns 0 and doesn't dispatch notifications when no products are moved" do
        moved_count = described_class.new(
          warehouse_id: to_warehouse.id
        ).move

        expect(moved_count).to eq(0)
      end

      it "returns 0 when empty purchase_items_ids array is provided" do
        moved_count = described_class.new(
          warehouse_id: to_warehouse.id,
          purchase_items_ids: []
        ).move

        expect(moved_count).to eq(0)
      end

      it "doesn't call any notifications when nothing is moved" do
        allow(PurchasedNotifier).to receive(:new)

        described_class.new(
          warehouse_id: to_warehouse.id,
          purchase_items_ids: []
        ).move

        expect(PurchasedNotifier).not_to have_received(:new)
      end
    end

    context "when purchase_items_ids contains non-existent IDs" do
      it "only moves existing products" do
        non_existent_ids = [99999, 88888]
        all_ids = purchase_items.map(&:id) + non_existent_ids

        moved_count = described_class.new(
          warehouse_id: to_warehouse.id,
          purchase_items_ids: all_ids
        ).move

        expect(moved_count).to eq(3)
        purchase_items.each do |product|
          expect(product.reload.warehouse_id).to eq(to_warehouse.id)
        end
      end
    end

    context "when purchase has existing purchase_items" do
      it "uses purchase's purchase_items when no specific IDs are provided" do
        # Ensure we're working with the purchase that has the products
        purchase_items # This creates the products and associates them with the purchase

        moved_count = described_class.new(
          warehouse_id: to_warehouse.id,
          purchase: purchase
        ).move

        expect(moved_count).to eq(3) # Now matches the purchase amount and created products
        purchase_items.each do |product|
          expect(product.reload.warehouse_id).to eq(to_warehouse.id)
        end
      end

      it "prioritizes purchase_items_ids over purchase's products" do
        # Create a separate purchase with its own products
        separate_purchase = create(:purchase, amount: 2)
        other_products = create_list(:purchase_item, 2, warehouse: from_warehouse, purchase: separate_purchase)

        # Ensure the original purchase has its products
        purchase_items

        moved_count = described_class.new(
          warehouse_id: to_warehouse.id,
          purchase: purchase,
          purchase_items_ids: other_products.map(&:id)
        ).move

        expect(moved_count).to eq(2) # Only the 2 specifically selected products
        other_products.each do |product|
          expect(product.reload.warehouse_id).to eq(to_warehouse.id)
        end

        # Original purchase products should remain unchanged
        purchase_items.each do |product|
          expect(product.reload.warehouse_id).to eq(from_warehouse.id)
        end
      end
    end

    context "error handling" do
      it "raises error when warehouse doesn't exist" do
        expect {
          described_class.new(
            warehouse_id: 99999,
            purchase_items_ids: purchase_items.map(&:id)
          )
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
