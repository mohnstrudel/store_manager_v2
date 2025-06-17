require "rails_helper"

RSpec.describe PurchaseLinker do
  let(:supplier) { create(:supplier) }
  let(:product) { create(:product) }
  let(:edition) { create(:edition, product:) }
  let(:active_status) { Sale.active_status_names.first }
  let(:completed_status) { Sale.completed_status_names.first }

  describe "#initialize" do
    it "raises ArgumentError when purchase is blank" do
      expect { described_class.new(nil) }.to raise_error(ArgumentError, "Missing purchase")
    end

    it "initializes with a valid purchase" do
      purchase = create(:purchase, product: product)
      expect { described_class.new(purchase) }.not_to raise_error
    end
  end

  describe "#link" do
    context "when there are no purchased products" do
      let(:purchase) { create(:purchase, product: product, amount: 3) }

      it "returns nil" do
        linker = described_class.new(purchase)
        expect(linker.link).to be_nil
      end
    end

    context "when linking sold products" do
      let(:purchase) { create(:purchase, product:, amount: 3) }
      let!(:purchase_items) do
        3.times.map { create(:purchase_item, purchase:) }
      end

      context "with an active status" do
        let!(:sale) { create(:sale, status: active_status) }
        let!(:sale_item) { create(:sale_item, product:, sale:, edition_id: nil, qty: 5) }

        it "links purchased items with sold products" do
          linker = described_class.new(purchase)
          linked_ids = linker.link

          expect(linked_ids).to match_array(purchase_items.pluck(:id))
          purchase_items.each do |pp|
            expect(pp.reload.sale_item_id).to eq(sale_item.id)
          end
        end

        it "respects the purchase amount limit" do
          purchase.update(amount: 2)
          linker = described_class.new(purchase)
          linked_ids = linker.link

          expect(linked_ids.size).to eq(2)
          expect(purchase_items.count { |i| i.reload.sale_item_id.nil? }).to eq(1)
        end
      end

      context "when there are multiple product sales" do
        let!(:sale1) { create(:sale, status: active_status) }
        let!(:sale2) { create(:sale, status: active_status) }
        let!(:sale_item1) { create(:sale_item, product:, sale: sale1, qty: 1, edition_id: nil) }
        let!(:sale_item2) { create(:sale_item, product:, sale: sale2, qty: 4, edition_id: nil) }

        it "links purchased products to multiple product sales" do
          linker = described_class.new(purchase)
          linked_ids = linker.link
          linked_sale_item_ids = purchase_items.map(&:reload).pluck(:sale_item_id)

          expect(linked_ids.size).to eq(3)
          expect(linked_ids).to match_array(purchase_items.pluck(:id))
          expect(linked_sale_item_ids).to include(sale_item1.id, sale_item2.id)
        end
      end

      context "when there are not enough product sales" do
        let!(:sale) { create(:sale, status: active_status) }
        let!(:sale_item) { create(:sale_item, product: product, sale: sale, qty: 1, edition_id: nil) }

        it "links as many purchased products as possible" do
          linker = described_class.new(purchase)
          linked_ids = linker.link

          expect(linked_ids.size).to eq(1)
          expect(purchase_items[0].reload.sale_item_id).to eq(sale_item.id)
          expect(purchase_items[1].reload.sale_item_id).to be_nil
          expect(purchase_items[2].reload.sale_item_id).to be_nil
        end
      end

      context "when product sales are not active" do
        let!(:sale) { create(:sale, status: completed_status) }
        let!(:sale_item) { create(:sale_item, product: product, sale: sale, qty: 5) }

        it "does not link to inactive sales" do
          linker = described_class.new(purchase)
          linked_ids = linker.link

          expect(linked_ids).to be_empty
          purchase_items.each do |pp|
            expect(pp.reload.sale_item_id).to be_nil
          end
        end
      end

      context "when product sales are not linkable" do
        let!(:sale) { create(:sale, status: active_status) }
        let!(:sale_item) { create(:sale_item, product: product, sale: sale, qty: 3, purchase_items_count: 3) }

        it "does not link to fully linked sales" do
          linker = described_class.new(purchase)
          linked_ids = linker.link

          expect(linked_ids).to be_empty
          purchase_items.each do |pp|
            expect(pp.reload.sale_item_id).to be_nil
          end
        end
      end
    end

    context "when linking with sold editions" do
      let(:purchase) { create(:purchase, product: product, edition: edition, amount: 3) }
      let!(:purchase_items) do
        3.times.map { create(:purchase_item, purchase: purchase) }
      end

      context "when there are available product sales for the edition" do
        let!(:sale) { create(:sale, status: active_status) }
        let!(:sale_item) { create(:sale_item, product: product, edition: edition, sale: sale, qty: 5) }

        it "links purchased products to product sales with matching edition" do
          linker = described_class.new(purchase)
          linked_ids = linker.link

          expect(linked_ids).to match_array(purchase_items.map(&:id))
          purchase_items.each do |pp|
            expect(pp.reload.sale_item_id).to eq(sale_item.id)
          end
        end
      end

      context "when there are no product sales for the edition" do
        let!(:other_edition) { create(:edition, product: product) }
        let!(:sale) { create(:sale, status: active_status) }
        let!(:sale_item) { create(:sale_item, product: product, edition: other_edition, sale: sale, qty: 5) }

        it "does not link purchased products" do
          linker = described_class.new(purchase)
          linked_ids = linker.link

          expect(linked_ids).to be_empty
          purchase_items.each do |pp|
            expect(pp.reload.sale_item_id).to be_nil
          end
        end
      end
    end

    context "edge cases" do
      let(:purchase) { create(:purchase, product: product, amount: 0) }
      let!(:purchase_items) { [] }

      it "handles purchase with zero amount" do
        linker = described_class.new(purchase)
        expect(linker.link).to be_nil
      end

      it "handles product sale with zero quantity" do
        purchase.update(amount: 3)
        purchase_items = 3.times.map { create(:purchase_item, purchase:) }
        sale = create(:sale, status: active_status)
        create(:sale_item, product:, sale:, qty: 0)

        linker = described_class.new(purchase)
        linked_ids = linker.link

        expect(linked_ids).to be_empty
        purchase_items.each do |pp|
          expect(pp.reload.sale_item_id).to be_nil
        end
      end

      it "handles all product sales being fully linked" do
        purchase.update(amount: 3)
        purchase_items = 3.times.map { create(:purchase_item, purchase:) }
        sale = create(:sale, status: active_status)
        create(:sale_item, product:, sale:, qty: 3, purchase_items_count: 3)

        linker = described_class.new(purchase)
        linked_ids = linker.link

        expect(linked_ids).to be_empty
        purchase_items.each do |pp|
          expect(pp.reload.sale_item_id).to be_nil
        end
      end
    end

    context "error handling" do
      let(:purchase) { create(:purchase, product: product, amount: 3) }
      let!(:purchase_items) do
        3.times.map { create(:purchase_item, purchase:) }
      end

      it "handles invalid product sale during linking" do
        sale = create(:sale, status: active_status)
        create(:sale_item, product:, sale:, qty: 3)

        # Make product sale invalid by setting qty to nil
        allow_any_instance_of(SaleItem).to receive(:valid?).and_return(false)

        linker = described_class.new(purchase)
        linked_ids = linker.link

        expect(linked_ids).to be_empty
        purchase_items.each do |pp|
          expect(pp.reload.sale_item_id).to be_nil
        end
      end

      it "handles invalid purchase during linking" do
        sale = create(:sale, status: active_status)
        create(:sale_item, product:, sale:, qty: 3)

        # Make purchase invalid
        allow_any_instance_of(Purchase).to receive(:valid?).and_return(false)

        linker = described_class.new(purchase)
        linked_ids = linker.link

        expect(linked_ids).to be_empty
        purchase_items.each do |pp|
          expect(pp.reload.sale_item_id).to be_nil
        end
      end
    end

    context "transaction safety" do
      let(:purchase) { create(:purchase, product: product, amount: 3) }
      let!(:purchase_items) do
        3.times.map { create(:purchase_item, purchase:) }
      end

      it "ensures atomic linking (all or nothing)" do
        sale = create(:sale, status: active_status)
        sale_item = create(:sale_item, product:, sale:, qty: 3)

        # Simulate an error during the second link
        allow_any_instance_of(PurchaseItem).to receive(:update).and_wrap_original do |original_method, *args|
          if args.first[:sale_item_id] == sale_item.id && original_method.receiver == purchase_items[1]
            raise ActiveRecord::RecordInvalid.new(original_method.receiver)
          end
          original_method.call(*args)
        end

        linker = described_class.new(purchase)
        linked_ids = linker.link

        expect(linked_ids).to be_empty
        purchase_items.each do |pp|
          expect(pp.reload.sale_item_id).to be_nil
        end
      end
    end
  end
end
