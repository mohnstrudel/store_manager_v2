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
      let(:variant_a) { create(:variant, :with_version, product:, version_value: "A") }
      let(:variant_b) { create(:variant, :with_version, product:, version_value: "B") }
      let(:variant_c) { create(:variant, :with_version, product:, version_value: "C") }
      let(:variant_without_sale) { create(:variant, :with_version, product:, version_value: "D") }
      let!(:sale_item_a) { create(:sale_item, sale:, product:, variant: variant_a, qty: 2) }
      let!(:sale_item_b) { create(:sale_item, sale:, product:, variant: variant_b, qty: 1) }
      let!(:sale_item_c) { create(:sale_item, sale:, product:, variant: variant_c, qty: 1) }

      let!(:purchase_a) { create(:purchase, product:, variant: variant_a, amount: 2) }
      let!(:purchase_b) { create(:purchase, product:, variant: variant_b, amount: 1) }
      let!(:purchase_c) { create(:purchase, product:, variant: variant_c, amount: 1) }
      let!(:purchase_without_sale) { create(:purchase, product:, variant: variant_without_sale, amount: 1) }

      # rubocop:todo RSpec/IndexedLet
      let!(:purchase_item_a1) { create(:purchase_item, purchase: purchase_a, warehouse:) }
      # rubocop:enable RSpec/IndexedLet
      # rubocop:todo RSpec/IndexedLet
      let!(:purchase_item_a2) { create(:purchase_item, purchase: purchase_a, warehouse:) }
      # rubocop:enable RSpec/IndexedLet
      let!(:purchase_item_b1) { create(:purchase_item, purchase: purchase_b, warehouse:) }
      let!(:purchase_item_c1) { create(:purchase_item, purchase: purchase_c, warehouse:) }
      let!(:purchase_item_wrong_variant) { create(:purchase_item, purchase: purchase_without_sale, warehouse:) }

      before { sale.link_with_purchase_items }

      it "links only purchased products with matching variant to sale_item" do
        aggregate_failures do
          expect(purchase_item_a1.reload.sale_item_id).to eq(sale_item_a.id)
          expect(purchase_item_a2.reload.sale_item_id).to eq(sale_item_a.id)
          expect(purchase_item_b1.reload.sale_item_id).to eq(sale_item_b.id)
          expect(purchase_item_c1.reload.sale_item_id).to eq(sale_item_c.id)
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
    end

    it "delegates to the exact-link flow" do
      expect(sale.link_purchase_items!).to eq(purchase_item_ids)
      expect(sale).to have_received(:link_with_purchase_items)
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

  describe ".with_missing_purchases" do
    def sale_with_line(qty:, linked:, product: create(:product), **sale_attributes)
      sale = create(:sale, status: active_status, **sale_attributes)
      sale_item = create(:sale_item, sale:, product:, qty:)
      link_purchase_items(sale_item, linked)
      sale
    end

    def link_purchase_items(sale_item, count)
      return if count.zero?

      purchase = create(:purchase, supplier:, product: sale_item.product, amount: count)
      create_list(:purchase_item, count, purchase:, warehouse:, sale_item:)
    end

    def create_follow_up_plan(origin_order_id:, follow_up_order_id:)
      SalePaymentPlan.reconcile!(
        attributes: {
          provider: "seal",
          external_id: "subscription-#{origin_order_id}",
          external_origin_order_id: origin_order_id,
          kind: "installments",
          status: "active",
          expected_parts: 2,
          synced_at: Time.current
        },
        parts: [
          {provider_part_id: "#{origin_order_id}-1", sequence: 1, external_order_id: origin_order_id},
          {provider_part_id: "#{origin_order_id}-2", sequence: 2, external_order_id: follow_up_order_id}
        ]
      )
    end

    it "matches a line whose sold quantity exceeds its actual linked purchase items" do
      none_linked = sale_with_line(qty: 3, linked: 0)
      some_linked = sale_with_line(qty: 3, linked: 1)
      sale_with_line(qty: 3, linked: 3)
      sale_with_line(qty: 3, linked: 4)

      expect(described_class.with_missing_purchases).to contain_exactly(none_linked, some_linked)
    end

    it "does not let one overcovered line offset another short line" do
      sale = create(:sale, status: active_status)
      overcovered = create(:sale_item, sale:, product: create(:product), qty: 2)
      short = create(:sale_item, sale:, product: create(:product), qty: 2)
      link_purchase_items(overcovered, 3)
      link_purchase_items(short, 1)

      expect(described_class.with_missing_purchases).to contain_exactly(sale)
    end

    it "returns a sale with several short lines once" do
      sale = create(:sale, status: active_status)
      create(:sale_item, sale:, product: create(:product), qty: 2)
      create(:sale_item, sale:, product: create(:product), qty: 1)

      expect(described_class.with_missing_purchases.pluck(:id)).to eq([sale.id])
    end

    it "ignores orders without eligible merchandise demand" do
      create(:sale, status: active_status)
      sale_with_line(qty: 2, linked: 0, product: create(:product, non_catalog: true))
      sale_with_line(qty: nil, linked: 0)
      sale_with_line(qty: 0, linked: 0)
      sale_with_line(qty: -1, linked: 0)
      origin_item = create(:sale_item, sale: create(:sale, status: active_status), qty: 1)
      link_purchase_items(origin_item, 1)
      attributed = create(:sale, status: active_status)
      create(:sale_item, sale: attributed, product: origin_item.product, qty: 1, origin_sale_item: origin_item)

      expect(described_class.with_missing_purchases).to be_empty
    end

    it "ignores a recognized follow-up payment before and after its line is attributed" do
      origin = create(:sale, status: active_status, shopify_store_id: "gid://shopify/Order/900")
      origin_item = create(:sale_item, sale: origin, product:, qty: 1)
      link_purchase_items(origin_item, 1)
      follow_up = create(:sale, status: active_status, shopify_store_id: "gid://shopify/Order/901")
      follow_up_item = create(:sale_item, sale: follow_up, product: create(:product), qty: 1)
      create_follow_up_plan(origin_order_id: "900", follow_up_order_id: "901")

      expect(described_class.with_missing_purchases).to be_empty

      follow_up_item.apply_installment_origin!(origin_item)

      expect(described_class.with_missing_purchases).to be_empty
    end

    it "uses persisted purchase links instead of the cached count" do
      cache_says_covered = sale_with_line(qty: 1, linked: 0)
      cache_says_covered.sale_items.first.update_columns(purchase_items_count: 1)
      cache_says_short = sale_with_line(qty: 1, linked: 1)
      cache_says_short.sale_items.first.update_columns(purchase_items_count: 0)

      expect(described_class.with_missing_purchases).to contain_exactly(cache_says_covered)
    end

    it "follows link and unlink changes" do
      sale = sale_with_line(qty: 1, linked: 0)
      sale_item = sale.sale_items.first

      expect(described_class.with_missing_purchases).to contain_exactly(sale)

      link_purchase_items(sale_item, 1)
      expect(described_class.with_missing_purchases).to be_empty

      PurchaseItem.where(sale_item:).update_all(sale_item_id: nil)
      expect(described_class.with_missing_purchases).to contain_exactly(sale)
    end
  end
end
