# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product do
  describe "#apply_initial_purchase!" do
    let(:product) { create(:product) }
    let(:warehouse) { create(:warehouse) }
    let(:supplier) { create(:supplier) }
    let!(:purchase) { create(:purchase, product:, supplier:, amount: 2, item_price: 10) }

    before do
      allow_any_instance_of(Purchase).to receive(:link_purchase_items).and_return([]) # rubocop:todo RSpec/AnyInstance
      allow(PurchaseItem).to receive(:notify_order_status!)
    end

    it "creates warehouse items, links sales, and creates a payment" do
      expect {
        product.apply_initial_purchase!(warehouse_id: warehouse.id, payment_value: "20")
      }.to change(PurchaseItem, :count).by(2)
        .and change(Payment, :count).by(1)

      aggregate_failures do
        expect(purchase.reload.purchase_items.pluck(:warehouse_id).uniq).to eq([warehouse.id])
        expect(purchase.payments.first.value).to eq(BigDecimal("20"))
        expect(PurchaseItem).to have_received(:notify_order_status!).with(
          purchase_item_ids: []
        )
      end
    end

    it "updates the existing first payment instead of creating a duplicate" do
      existing_payment = create(:payment, purchase:, value: 10)

      expect {
        product.apply_initial_purchase!(payment_value: "25")
      }.not_to change(Payment, :count)

      aggregate_failures do
        expect(existing_payment.reload.value).to eq(BigDecimal("25"))
        expect(purchase.reload.payments.count).to eq(1)
      end
    end
  end
end
