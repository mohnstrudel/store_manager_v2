require "rails_helper"

PURCHASED_AMOUNT = 5

describe PurchaseCreator do
  let!(:warehouse) { create(:warehouse, is_default: true) }
  let(:product) { create(:product) }
  let(:supplier) { create(:supplier) }
  let(:purchase_params) {
    attributes_for(:purchase,
      supplier_id: supplier.id,
      product_id: product.id,
      amount: 5,
      warehouse_id: warehouse.id)
  }

  describe "#call" do
    it "creates a purchase with purchased products" do
      purchase = described_class.new(purchase_params).create

      expect(purchase.purchased_products.count).to eq(PURCHASED_AMOUNT)
    end

    it "links purchased products with the correct warehouse" do
      purchase = described_class.new(purchase_params).create
      purchased_products_warehouse_id = purchase
        .purchased_products
        .pluck(:warehouse_id)
        .uniq

      expect(purchased_products_warehouse_id).to eq([warehouse.id])
    end

    context "when we purchased a variation" do
      it "links with variations correctly" do
        active_status = Sale.active_status_names.first
        variation = create(:variation)
        product_sale = create(:product_sale,
          product: product,
          qty: 2,
          sale: create(:sale, status: active_status))
        variation_sale = create(:product_sale,
          product: product,
          variation: variation,
          qty: 2,
          sale: create(:sale, status: active_status))

        variation_params = purchase_params.merge(
          variation_id: variation.id,
          product_id: product.id,
          amount: 3
        )

        purchase = described_class.new(variation_params).create
        linked_product_sales_ids = purchase
          .purchased_products
          .pluck(:product_sale_id)

        expect(linked_product_sales_ids).to include(variation_sale.id)
        expect(linked_product_sales_ids).not_to include(product_sale.id)
      end
    end

    context "when there are unlinked product sales" do
      let!(:product_sale_one) {
        create(:product_sale, product: product, variation: nil, qty: 2)
      }
      let!(:product_sale_two) {
        create(:product_sale, product: product, variation: nil, qty: 2)
      }
      let(:inactive_product_sale) {
        create(:product_sale, product: product, variation: nil, qty: 2)
      }

      before do
        allow(Notification).to receive(:dispatch)
        inactive_product_sale.sale.update(status: :cancelled)
      end

      it "links purchased products to product sales" do
        described_class.new(purchase_params).create

        linked_purchased_products = PurchasedProduct.where.not(
          product_sale_id: nil
        )
        linkied_product_sales = linked_purchased_products
          .pluck(:product_sale_id)
          .uniq

        expect(linked_purchased_products.count).to eq(4)
        expect(linkied_product_sales).to eq(
          [product_sale_one.id, product_sale_two.id]
        )
      end

      it "dispatches notifications for each linked product" do
        described_class.new(purchase_params).create

        expect(Notification).to have_received(:dispatch)
          .exactly(4).times
          .with(
            event: Notification.event_types[:product_purchased],
            context: hash_including(:purchased_product_id)
          )
      end

      it "leaves excess purchased products unlinked" do
        described_class.new(purchase_params).create

        unlinked_products = PurchasedProduct.where(product_sale_id: nil)

        expect(unlinked_products.count).to eq(1)
      end

      it "doesn't link purchased products to inactive sales" do
        described_class.new(purchase_params).create

        linked_sale_ids = PurchasedProduct
          .where.not(product_sale_id: nil)
          .pluck(:product_sale_id)
          .uniq

        expect(linked_sale_ids).not_to include(inactive_product_sale.id)
      end
    end

    context "when there are no product sales to link with" do
      it "creates purchased products without linking them" do
        described_class.new(purchase_params).create

        unlinked_products = PurchasedProduct.where(product_sale_id: nil)

        expect(unlinked_products.count).to eq(PURCHASED_AMOUNT)
      end
    end
  end
end
