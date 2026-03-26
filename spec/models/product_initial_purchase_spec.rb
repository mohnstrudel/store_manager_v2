# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product do
  describe "#apply_initial_purchase!" do
    let(:product) { create(:product) }
    let(:warehouse) { create(:warehouse) }
    let(:supplier) { create(:supplier) }

    it "creates a purchase, warehouse items, and a payment" do # rubocop:disable RSpec/MultipleExpectations
      expect {
        product.apply_initial_purchase!(
          supplier_id: supplier.id,
          amount: "2",
          item_price: "10",
          order_reference: "PO-1",
          warehouse_id: warehouse.id,
          payment_value: "20"
        )
      }.to change(Purchase, :count).by(1)
        .and change(PurchaseItem, :count).by(2)
        .and change(Payment, :count).by(1)

      purchase = product.purchases.order(:id).last

      expect(purchase.supplier).to eq(supplier)
      expect(purchase.order_reference).to eq("PO-1")
      expect(purchase.purchase_items.pluck(:warehouse_id).uniq).to eq([warehouse.id])
      expect(purchase.payments.pluck(:value)).to eq([BigDecimal(20)])
    end

    it "does nothing when the initial purchase section is blank" do
      expect {
        product.apply_initial_purchase!({})
      }.not_to change(Purchase, :count)
    end
  end
end
