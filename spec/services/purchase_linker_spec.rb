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
      let!(:purchased_products) do
        3.times.map { create(:purchased_product, purchase:) }
      end

      context "with an active status" do
        let!(:sale) { create(:sale, status: active_status) }
        let!(:product_sale) { create(:product_sale, product:, sale:, edition_id: nil, qty: 5) }

        it "links purchased items with sold products" do
          linker = described_class.new(purchase)
          linked_ids = linker.link

          expect(linked_ids).to match_array(purchased_products.pluck(:id))
          purchased_products.each do |pp|
            expect(pp.reload.product_sale_id).to eq(product_sale.id)
          end
        end

        it "respects the purchase amount limit" do
          purchase.update(amount: 2)
          linker = described_class.new(purchase)
          linked_ids = linker.link

          expect(linked_ids.size).to eq(2)
          expect(purchased_products.count { |i| i.reload.product_sale_id.nil? }).to eq(1)
        end
      end

      context "when there are multiple product sales" do
        let!(:sale1) { create(:sale, status: active_status) }
        let!(:sale2) { create(:sale, status: active_status) }
        let!(:product_sale1) { create(:product_sale, product:, sale: sale1, qty: 1, edition_id: nil) }
        let!(:product_sale2) { create(:product_sale, product:, sale: sale2, qty: 4, edition_id: nil) }

        it "links purchased products to multiple product sales" do
          linker = described_class.new(purchase)
          linked_ids = linker.link
          linked_product_sale_ids = purchased_products.map(&:reload).pluck(:product_sale_id)

          expect(linked_ids.size).to eq(3)
          expect(linked_ids).to match_array(purchased_products.pluck(:id))
          expect(linked_product_sale_ids).to include(product_sale1.id, product_sale2.id)
        end
      end

      context "when there are not enough product sales" do
        let!(:sale) { create(:sale, status: active_status) }
        let!(:product_sale) { create(:product_sale, product: product, sale: sale, qty: 1, edition_id: nil) }

        it "links as many purchased products as possible" do
          linker = described_class.new(purchase)
          linked_ids = linker.link

          expect(linked_ids.size).to eq(1)
          expect(purchased_products[0].reload.product_sale_id).to eq(product_sale.id)
          expect(purchased_products[1].reload.product_sale_id).to be_nil
          expect(purchased_products[2].reload.product_sale_id).to be_nil
        end
      end

      context "when product sales are not active" do
        let!(:sale) { create(:sale, status: completed_status) }
        let!(:product_sale) { create(:product_sale, product: product, sale: sale, qty: 5) }

        it "does not link to inactive sales" do
          linker = described_class.new(purchase)
          linked_ids = linker.link

          expect(linked_ids).to be_empty
          purchased_products.each do |pp|
            expect(pp.reload.product_sale_id).to be_nil
          end
        end
      end

      context "when product sales are not linkable" do
        let!(:sale) { create(:sale, status: active_status) }
        let!(:product_sale) { create(:product_sale, product: product, sale: sale, qty: 3, purchased_products_count: 3) }

        it "does not link to fully linked sales" do
          linker = described_class.new(purchase)
          linked_ids = linker.link

          expect(linked_ids).to be_empty
          purchased_products.each do |pp|
            expect(pp.reload.product_sale_id).to be_nil
          end
        end
      end
    end

    context "when linking with sold editions" do
      let(:purchase) { create(:purchase, product: product, edition: edition, amount: 3) }
      let!(:purchased_products) do
        3.times.map { create(:purchased_product, purchase: purchase) }
      end

      context "when there are available product sales for the edition" do
        let!(:sale) { create(:sale, status: active_status) }
        let!(:product_sale) { create(:product_sale, product: product, edition: edition, sale: sale, qty: 5) }

        it "links purchased products to product sales with matching edition" do
          linker = described_class.new(purchase)
          linked_ids = linker.link

          expect(linked_ids).to match_array(purchased_products.map(&:id))
          purchased_products.each do |pp|
            expect(pp.reload.product_sale_id).to eq(product_sale.id)
          end
        end
      end

      context "when there are no product sales for the edition" do
        let!(:other_edition) { create(:edition, product: product) }
        let!(:sale) { create(:sale, status: active_status) }
        let!(:product_sale) { create(:product_sale, product: product, edition: other_edition, sale: sale, qty: 5) }

        it "does not link purchased products" do
          linker = described_class.new(purchase)
          linked_ids = linker.link

          expect(linked_ids).to be_empty
          purchased_products.each do |pp|
            expect(pp.reload.product_sale_id).to be_nil
          end
        end
      end
    end
  end
end
