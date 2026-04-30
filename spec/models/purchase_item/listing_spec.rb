# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseItem::Listing do
  describe ".for_warehouse_details" do
    it "preloads product variants through the purchase for warehouse rows" do
      purchase_item = create(:purchase_item)
      create(:variant, product: purchase_item.purchase.product)

      item = PurchaseItem.for_warehouse_details.find(purchase_item.id)
      product = item.purchase.product

      aggregate_failures do
        expect(item.association(:purchase)).to be_loaded
        expect(item.purchase.association(:product)).to be_loaded
        expect(product.association(:variants)).to be_loaded
      end
    end
  end
end
