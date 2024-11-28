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

    it "associates purchased products with the correct warehouse and purchase" do
      purchased_products = PurchasedProduct.where(purchase_id: purchase.id)

      expect(purchased_products.pluck(:warehouse_id).uniq).to eq([warehouse.id])
    end

    context "when there are unlinked product sales" do
      let!(:product_sale1) { create(:product_sale, product: product, qty: 2) }
      let!(:product_sale2) { create(:product_sale, product: product, qty: 2) }

      before do
        allow(Notification).to receive(:dispatch)
        purchase.create_purchased_products
      end

      it "links purchased products to product sales" do
        linked_purchased_products = PurchasedProduct.where.not(product_sale_id: nil)

        expect(linked_purchased_products.count).to eq(4)
        expect(linked_purchased_products.pluck(:product_sale_id).uniq.sort).to eq([product_sale1.id, product_sale2.id].sort)
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
        purchase.create_purchased_products

        expect(unlinked_products.count).to eq(PURCHASED_AMOUNT)
      end
    end
  end
end
