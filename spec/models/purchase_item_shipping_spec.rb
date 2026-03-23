# frozen_string_literal: true

require "rails_helper"

describe PurchaseItem do
  describe "#cost" do
    let(:purchase) { create(:purchase, item_price: 50.0) }
    let(:purchase_item) { create(:purchase_item, purchase:, shipping_cost: 10.0) }

    it "calculates cost including item price and shipping" do
      expect(purchase_item.cost).to eq(60.0)
    end
  end

  describe "#update_purchase_shipping_total callback" do
    let(:purchase) { create(:purchase, shipping_total: 0) }

    describe "when purchase_item is created" do
      it "adds shipping_cost to purchase.shipping_total" do
        create(:purchase_item, purchase:, shipping_cost: 15.0)
        expect(purchase.reload.shipping_total).to eq(15.0)
      end

      it "accumulates shipping_cost from multiple items" do
        create(:purchase_item, purchase:, shipping_cost: 10.0)
        create(:purchase_item, purchase:, shipping_cost: 5.0)
        expect(purchase.reload.shipping_total).to eq(15.0)
      end
    end

    describe "when purchase_item is destroyed" do
      let!(:purchase_item) { create(:purchase_item, purchase:, shipping_cost: 20.0) }

      it "subtracts shipping_cost from purchase.shipping_total" do
        purchase_item.destroy

        expect(purchase.reload.shipping_total).to eq(0)
      end
    end

    describe "when shipping_cost is updated" do
      let!(:purchase_item) { create(:purchase_item, purchase:, shipping_cost: 10.0) }

      it "updates purchase.shipping_total with the difference" do
        purchase_item.update!(shipping_cost: 25.0)

        expect(purchase.reload.shipping_total).to eq(25.0)
      end

      it "handles decreasing shipping_cost" do
        purchase_item.update!(shipping_cost: 5.0)

        expect(purchase.reload.shipping_total).to eq(5.0)
      end
    end

    describe "when shipping_cost is zero" do
      it "does not change purchase.shipping_total" do
        create(:purchase_item, purchase:, shipping_cost: 0)
        expect(purchase.reload.shipping_total).to eq(0)
      end
    end
  end
end
