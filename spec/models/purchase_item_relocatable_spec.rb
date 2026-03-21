# frozen_string_literal: true

require "rails_helper"

describe PurchaseItem do
  describe "#relocate_to" do
    it "updates the warehouse_id" do
      purchase_item = create(:purchase_item)
      destination = create(:warehouse)

      purchase_item.relocate_to(destination.id)

      expect(purchase_item.reload.warehouse_id).to eq(destination.id)
    end
  end
end
