# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale do
  let(:warehouse) { create(:warehouse, is_default: true) }
  let(:product) { create(:product) }
  let(:supplier) { create(:supplier) }
  let(:purchase) { create(:purchase, supplier:, product:, amount: 3) }
  let(:active_status) { described_class.active_status_names.first }
  let(:completed_status) { described_class.completed_status_names.first }
  let(:cancelled_status) { described_class.cancelled_status_names.first }

  describe "#link_with_purchase_items" do
    context "when sale is active" do
      let(:sale) { create(:sale, status: active_status) }
      let!(:sale_item) { create(:sale_item, sale:, product:, qty: 2) }

      before do
        create_list(:purchase_item, 3, purchase:, warehouse:)
      end

      it "links up to qty purchased products to sale_item" do
        expect {
          sale.link_with_purchase_items
        }.to change { PurchaseItem.where(sale_item_id: sale_item.id).count }.from(0).to(2)
      end

      it "returns the ids of linked purchased products" do
        linked_ids = sale.link_with_purchase_items

        aggregate_failures do
          expect(linked_ids.size).to eq(2)
          expect(PurchaseItem.where(id: linked_ids, sale_item_id: sale_item.id).count).to eq(2)
        end
      end

      it "does not link more than needed purchased products" do
        create_list(:purchase_item, 2, sale_item:, purchase:, warehouse:)
        expect(sale.link_with_purchase_items.size).to eq(0)
      end
    end

    context "when sale is completed" do
      let(:sale) { create(:sale, status: completed_status) }
      let!(:sale_item) { create(:sale_item, sale:, product:, qty: 1) }

      before do
        create(:purchase_item, purchase:, warehouse:)
      end

      it "links purchased products" do
        expect {
          sale.link_with_purchase_items
        }.to change { PurchaseItem.where(sale_item_id: sale_item.id).count }.from(0).to(1)
      end
    end

    context "when sale is cancelled" do
      let(:sale) { create(:sale, status: cancelled_status) }
      let!(:sale_item) { create(:sale_item, sale:, product:, qty: 1) }

      before do
        create(:purchase_item, purchase:, warehouse:)
      end

      it "does not link any purchased products" do
        aggregate_failures do
          expect(sale.link_with_purchase_items).to be_nil
          expect(PurchaseItem.where(sale_item_id: sale_item.id).count).to eq(0)
        end
      end
    end

    context "when sale_items have variants" do
      let(:sale) { create(:sale, status: active_status) }
      let(:variant_a) { create(:variant, :with_version, version_value: "A") }
      let(:variant_b) { create(:variant, :with_version, version_value: "B") }
      let!(:sale_item_a) { create(:sale_item, sale:, product:, variant: variant_a, qty: 2) }
      let!(:sale_item_b) { create(:sale_item, sale:, product:, variant: variant_b, qty: 1) }
      let!(:sale_item_none) { create(:sale_item, sale:, product:, variant: nil, qty: 1) }

      let!(:purchase_a) { create(:purchase, product:, variant: variant_a, amount: 2) }
      let!(:purchase_b) { create(:purchase, product:, variant: variant_b, amount: 1) }
      let!(:purchase_none) { create(:purchase, product:, variant: nil, amount: 1) }

      # rubocop:todo RSpec/IndexedLet
      let!(:purchase_item_a1) { create(:purchase_item, purchase: purchase_a, warehouse:) }
      # rubocop:enable RSpec/IndexedLet
      # rubocop:todo RSpec/IndexedLet
      let!(:purchase_item_a2) { create(:purchase_item, purchase: purchase_a, warehouse:) }
      # rubocop:enable RSpec/IndexedLet
      let!(:purchase_item_b1) { create(:purchase_item, purchase: purchase_b, warehouse:) }
      let!(:purchase_item_none) { create(:purchase_item, purchase: purchase_none, warehouse:) }
      let!(:purchase_item_wrong_variant) { create(:purchase_item, purchase:, warehouse:) }

      before { sale.link_with_purchase_items }

      it "links only purchased products with matching variant to sale_item" do
        aggregate_failures do
          expect(purchase_item_a1.reload.sale_item_id).to eq(sale_item_a.id)
          expect(purchase_item_a2.reload.sale_item_id).to eq(sale_item_a.id)
          expect(purchase_item_b1.reload.sale_item_id).to eq(sale_item_b.id)
          expect(purchase_item_none.reload.sale_item_id).to eq(sale_item_none.id)
        end
      end

      it "does not link purchased products with mismatched variant" do
        expect(purchase_item_wrong_variant.reload.sale_item_id).to be_nil
      end

      it "does not link more purchased products than sale_item qty" do
        extra = create(:purchase_item, purchase: purchase_a, warehouse:)
        sale.link_with_purchase_items

        aggregate_failures do
          expect([purchase_item_a1, purchase_item_a2, extra].count { |purchase_item| purchase_item.reload.sale_item_id == sale_item_a.id }).to eq(2)
          expect(extra.reload.sale_item_id).to be_nil
        end
      end

      it "does not relink already linked purchased products" do
        purchase_item_a1.update!(sale_item_id: sale_item_a.id)
        sale.link_with_purchase_items
        expect(purchase_item_a1.reload.sale_item_id).to eq(sale_item_a.id)
      end
    end

    context "when there are no linkable sale_items" do
      let(:sale) { create(:sale, status: active_status) }

      it "returns an empty array" do
        expect(sale.link_with_purchase_items).to eq([])
      end
    end
  end

  describe "#link_purchase_items!" do
    let(:sale) { create(:sale, status: active_status) }
    let(:purchase_item_ids) { [1, 2, 3] }

    before do
      allow(sale).to receive(:link_with_purchase_items).and_return(purchase_item_ids)
      allow(PurchaseItem).to receive(:notify_order_status!)
    end

    it "links sale items and notifies purchase item changes" do
      sale.link_purchase_items!

      aggregate_failures do
        expect(sale).to have_received(:link_with_purchase_items)
        expect(PurchaseItem).to have_received(:notify_order_status!).with(
          purchase_item_ids:
        )
      end
    end
  end

  describe "#unlinked_sale_items?" do
    let(:sale) { create(:sale, status: active_status) }
    let!(:sale_item) { create(:sale_item, sale:, product:, qty: 2) }

    context "when all sale_items are linked" do
      before do
        create_list(:purchase_item, 2, sale_item:, purchase:, warehouse:)
      end

      it "returns nil" do
        expect(sale.unlinked_sale_items?).to be_nil
      end
    end

    context "when some sale_items are not fully linked" do
      before do
        create(:purchase_item, sale_item:, purchase:, warehouse:)
      end

      it "returns true if there are available purchase items" do
        create(:purchase_item, purchase:, warehouse:)
        expect(sale.unlinked_sale_items?).to be true
      end

      it "returns false if no purchase items available" do
        expect(sale.unlinked_sale_items?).to be false
      end
    end

    context "when no sale_items exist" do
      let(:sale) { create(:sale, status: active_status) }

      it "returns false" do
        expect(sale.unlinked_sale_items?).to be false
      end
    end
  end
end
