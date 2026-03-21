# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseItem::Financials do
  describe "#cost" do
    let(:purchase) { create(:purchase, item_price: 50.0) }
    let(:purchase_item) { create(:purchase_item, purchase:, shipping_cost: 10.0) }

    it "calculates cost including item price and shipping" do
      expect(purchase_item.cost).to eq(60.0)
    end
  end
end
