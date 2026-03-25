# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotifyCustomersAboutOrderLocationJob do
  let(:warehouse) { create(:warehouse) }
  let(:purchase) { create(:purchase) }
  let!(:purchase_item_with_sale) do
    create(:purchase_item,
      warehouse:,
      purchase:,
      sale_item: create(:sale_item, sale: create(:sale)))
  end
  let!(:purchase_item_without_sale) do
    create(:purchase_item,
      warehouse:,
      purchase:,
      sale_item: nil)
  end

  before do
    allow(PurchaseItem).to receive(:notify_order_status!)
  end

  describe "#perform" do
    it "creates notifications for purchased products with sales" do # rubocop:todo RSpec/MultipleExpectations
      described_class.perform_now

      expect(PurchaseItem).to have_received(:notify_order_status!)
        .with(purchase_item_ids: [purchase_item_with_sale.id])
    end

    it "does not create notifications for purchased products without sales" do
      described_class.perform_now

      expect(PurchaseItem).not_to have_received(:notify_order_status!)
        .with(purchase_item_ids: [purchase_item_without_sale.id])
    end
  end
end
