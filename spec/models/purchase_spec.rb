# == Schema Information
#
# Table name: purchases
#
#  id              :bigint           not null, primary key
#  amount          :integer
#  item_price      :decimal(8, 2)
#  order_reference :string
#  purchase_date   :datetime
#  slug            :string
#  synced          :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  product_id      :bigint
#  supplier_id     :bigint           not null
#  variation_id    :bigint
#
require "rails_helper"

PURCHASED_AMOUNT = 5

describe Purchase do
  describe "#create_purchased_products" do
    let!(:warehouse) { create(:warehouse, is_default: true) }
    let(:product) { create(:product) }
    let(:purchase) { create(:purchase, product:, amount: PURCHASED_AMOUNT) }

    it "creates the correct number of purchased products" do
      expect(purchase.purchased_products.count).to eq(PURCHASED_AMOUNT)
    end

    it "links purchased products with the correct warehouse and purchase" do
      purchased_products = PurchasedProduct.where(purchase_id: purchase.id)

      expect(purchased_products.pluck(:warehouse_id).uniq).to eq([warehouse.id])
    end

    context "when we purchased a variation" do
      it "links with variations correctly" do
        variation = create(:variation)
        product_sale = create(:product_sale, product:, qty: 2)
        variation_sale = create(:product_sale, variation:, qty: 2)
        variation_purchase = create(:purchase, variation:, product:, amount: 3)

        expect(variation_purchase.purchased_products.pluck(:product_sale_id)).to include(variation_sale.id)
        expect(variation_purchase.purchased_products.pluck(:product_sale_id)).not_to include(product_sale.id)
      end
    end

    context "when there are unlinked product sales" do
      let!(:product_sale_one) { create(:product_sale, product: product, variation: nil, qty: 2) }
      let!(:product_sale_two) { create(:product_sale, product: product, variation: nil, qty: 2) }

      before do
        allow(Notification).to receive(:dispatch)
        purchase.id
      end

      it "links purchased products to product sales" do
        linked_purchased_products = PurchasedProduct.where.not(product_sale_id: nil)

        expect(linked_purchased_products.count).to eq(4)
        expect(linked_purchased_products.pluck(:product_sale_id).uniq.sort).to eq([product_sale_one.id, product_sale_two.id].sort)
      end

      it "dispatches notifications for each linked product" do
        expect(Notification).to have_received(:dispatch)
          .exactly(4).times
          .with(
            event: Notification.event_types[:product_purchased],
            context: hash_including(:purchased_product_id)
          )
      end

      it "leaves excess purchased products unlinked" do
        unlinked_products = PurchasedProduct.where(product_sale_id: nil)

        expect(unlinked_products.count).to eq(1)
      end
    end

    context "when there are no product sales to link with" do
      it "creates purchased products without linking them" do
        unlinked_products = PurchasedProduct.where(product_sale_id: nil)
        purchase.id

        expect(unlinked_products.count).to eq(PURCHASED_AMOUNT)
      end
    end
  end
end
