require "rails_helper"

RSpec.describe Sale, type: :model do
  let(:warehouse) { create(:warehouse, is_default: true) }
  let(:product) { create(:product) }
  let(:supplier) { create(:supplier) }
  let(:purchase) { create(:purchase, supplier:, product:, amount: 3) }
  let(:active_status) { described_class.active_status_names.first }
  let(:completed_status) { described_class.completed_status_names.first }
  let(:cancelled_status) { described_class.cancelled_status_names.first }

  describe "#link_with_purchased_products" do
    context "when sale is active" do
      let(:sale) { create(:sale, status: active_status) }
      let!(:product_sale) { create(:product_sale, sale:, product:, qty: 2) }

      before do
        create_list(:purchased_product, 3, purchase:, warehouse:)
      end

      it "links up to qty purchased products to product_sale" do
        expect {
          sale.link_with_purchased_products
        }.to change { PurchasedProduct.where(product_sale_id: product_sale.id).count }.from(0).to(2)
      end

      it "returns the ids of linked purchased products" do
        linked_ids = sale.link_with_purchased_products
        expect(linked_ids.size).to eq(2)
        expect(PurchasedProduct.where(id: linked_ids, product_sale_id: product_sale.id).count).to eq(2)
      end

      it "does not link more than needed purchased products" do
        create_list(:purchased_product, 2, product_sale:, purchase:, warehouse:)
        expect(sale.link_with_purchased_products.size).to eq(0)
      end
    end

    context "when sale is completed" do
      let(:sale) { create(:sale, status: completed_status) }
      let!(:product_sale) { create(:product_sale, sale:, product:, qty: 1) }

      before do
        create(:purchased_product, purchase:, warehouse:)
      end

      it "links purchased products" do
        expect {
          sale.link_with_purchased_products
        }.to change { PurchasedProduct.where(product_sale_id: product_sale.id).count }.from(0).to(1)
      end
    end

    context "when sale is cancelled" do
      let(:sale) { create(:sale, status: cancelled_status) }
      let!(:product_sale) { create(:product_sale, sale:, product:, qty: 1) }

      before do
        create(:purchased_product, purchase:, warehouse:)
      end

      it "does not link any purchased products" do
        expect(sale.link_with_purchased_products).to be_nil
        expect(PurchasedProduct.where(product_sale_id: product_sale.id).count).to eq(0)
      end
    end

    context "when product_sales have editions" do
      let(:sale) { create(:sale, status: active_status) }
      let(:edition_a) { create(:edition, :with_version, version_value: "A") }
      let(:edition_b) { create(:edition, :with_version, version_value: "B") }
      let!(:product_sale_a) { create(:product_sale, sale:, product:, edition: edition_a, qty: 2) }
      let!(:product_sale_b) { create(:product_sale, sale:, product:, edition: edition_b, qty: 1) }
      let!(:product_sale_none) { create(:product_sale, sale:, product:, edition: nil, qty: 1) }

      let!(:purchase_a) { create(:purchase, product:, edition: edition_a, amount: 2) }
      let!(:purchase_b) { create(:purchase, product:, edition: edition_b, amount: 1) }
      let!(:purchase_none) { create(:purchase, product:, edition: nil, amount: 1) }

      let!(:purchased_product_a1) { create(:purchased_product, purchase: purchase_a, warehouse:) }
      let!(:purchased_product_a2) { create(:purchased_product, purchase: purchase_a, warehouse:) }
      let!(:purchased_product_b1) { create(:purchased_product, purchase: purchase_b, warehouse:) }
      let!(:purchased_product_none) { create(:purchased_product, purchase: purchase_none, warehouse:) }
      let!(:purchased_product_wrong_edition) { create(:purchased_product, purchase:, warehouse:) }

      before { sale.link_with_purchased_products }

      it "links only purchased products with matching edition to product_sale" do
        expect(purchased_product_a1.reload.product_sale_id).to eq(product_sale_a.id)
        expect(purchased_product_a2.reload.product_sale_id).to eq(product_sale_a.id)
        expect(purchased_product_b1.reload.product_sale_id).to eq(product_sale_b.id)
        expect(purchased_product_none.reload.product_sale_id).to eq(product_sale_none.id)
      end

      it "does not link purchased products with mismatched edition" do
        expect(purchased_product_wrong_edition.reload.product_sale_id).to be_nil
      end

      it "does not link more purchased products than product_sale qty" do
        extra = create(:purchased_product, purchase: purchase_a, warehouse:)
        sale.link_with_purchased_products
        expect([purchased_product_a1, purchased_product_a2, extra].count { |pp| pp.reload.product_sale_id == product_sale_a.id }).to eq(2)
        expect(extra.reload.product_sale_id).to be_nil
      end

      it "does not relink already linked purchased products" do
        purchased_product_a1.update!(product_sale_id: product_sale_a.id)
        sale.link_with_purchased_products
        expect(purchased_product_a1.reload.product_sale_id).to eq(product_sale_a.id)
      end
    end

    context "when there are no linkable product_sales" do
      let(:sale) { create(:sale, status: active_status) }

      it "returns an empty array" do
        expect(sale.link_with_purchased_products).to eq([])
      end
    end
  end
end
