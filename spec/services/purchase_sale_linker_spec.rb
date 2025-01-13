require "rails_helper"

ACTIVE_STATUS = Sale.active_status_names.first
CANCELLED_STATUS = "cancelled"

describe PurchaseSaleLinker do
  let(:warehouse) { create(:warehouse, is_default: true) }
  let(:product) { create(:product) }
  let(:supplier) { create(:supplier) }
  let(:purchase) { create(:purchase, supplier:, product:, amount: 3) }
  let(:active_sale) {
    create(:sale, status: ACTIVE_STATUS)
  }
  let(:cancelled_sale) { create(:sale, status: CANCELLED_STATUS) }

  describe "#link" do
    context "when linking from purchase" do
      let!(:product_sale_active) {
        create(:product_sale, product:, sale: active_sale, qty: 2)
      }
      let!(:product_sale_cancelled) {
        create(:product_sale, product:, sale: cancelled_sale, qty: 2)
      }

      before do
        create_list(:purchased_product, 3, purchase:, warehouse:)
      end

      it "does not link purchase to cancelled product sales" do
        described_class.new(purchase:).link

        linked_sale_ids = purchase.purchased_products
          .where.not(product_sale_id: nil)
          .pluck(:product_sale_id)
          .uniq

        expect(linked_sale_ids).not_to include(product_sale_cancelled.id)
      end

      it "links purchase to active product sales" do
        described_class.new(purchase:).link

        linked_sale_ids = purchase.purchased_products
          .where.not(product_sale_id: nil)
          .pluck(:product_sale_id)
          .uniq

        expect(linked_sale_ids).to include(product_sale_active.id)
      end

      it "does not link purchase to product sales with no quantity left" do
        create_list(:purchased_product, 2, product:, warehouse:, product_sale: product_sale_active)

        linked_count = described_class.new(purchase:).link.size

        expect(linked_count).to eq(0)
      end

      context "when purchase has variation" do
        let(:variation) { create(:variation) }
        let(:purchase_with_variation) {
          create(:purchase, supplier:, product:, variation:, amount: 2)
        }
        let!(:product_sale_with_variation) {
          create(:product_sale, product:, variation:, sale: active_sale, qty: 1)
        }
        let!(:product_sale_without_variation) {
          create(:product_sale, product:, sale: active_sale, qty: 1)
        }

        before do
          purchase_with_variation.purchased_products.create([
            {warehouse:},
            {warehouse:}
          ])
        end

        it "only links to product sales with matching variation" do
          described_class.new(purchase: purchase_with_variation).link

          linked_sale_ids = purchase_with_variation.purchased_products
            .where.not(product_sale_id: nil)
            .pluck(:product_sale_id)
            .uniq

          expect(linked_sale_ids).to include(product_sale_with_variation.id)
          expect(linked_sale_ids).not_to include(product_sale_without_variation.id)
        end
      end
    end

    context "when linking from sale" do
      let(:sale) { create(:sale, status: ACTIVE_STATUS) }
      let!(:product_sale) { create(:product_sale, sale:, product:, qty: 2) }

      before do
        create_list(:purchased_product, 3, product:, warehouse:)
      end

      it "links active sale to available purchased products" do
        described_class.new(sale:).link

        linked_products = PurchasedProduct
          .where(product_sale_id: product_sale.id)

        expect(linked_products.count).to eq(2)
      end

      it "does not link cancelled sales" do
        sale.update(status: CANCELLED_STATUS)

        described_class.new(sale:).link

        linked_products = PurchasedProduct
          .where(product_sale_id: product_sale.id)

        expect(linked_products.count).to eq(0)
      end

      it "does not link more than needed purchased products" do
        create_list(:purchased_product, 2, product:, warehouse:, product_sale:)

        linked_count = described_class.new(sale:).link.size

        expect(linked_count).to eq(0)
      end
    end
  end
end
