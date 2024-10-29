# == Schema Information
#
# Table name: purchased_products
#
#  id              :bigint           not null, primary key
#  expenses        :decimal(8, 2)
#  height          :integer
#  length          :integer
#  shipping_price  :decimal(8, 2)
#  weight          :integer
#  width           :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  product_sale_id :bigint
#  purchase_id     :bigint
#  warehouse_id    :bigint           not null
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
        purchase.create_purchased_products
      end

      it "links purchased products to product sales" do
        linked_purchased_products = PurchasedProduct.where.not(product_sale_id: nil)

        expect(linked_purchased_products.count).to eq(4)
        expect(linked_purchased_products.pluck(:product_sale_id).uniq.sort).to eq([product_sale1.id, product_sale2.id].sort)
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
