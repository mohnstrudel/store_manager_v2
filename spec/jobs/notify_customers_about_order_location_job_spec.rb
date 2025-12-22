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

  let(:notifier) { instance_double(PurchasedNotifier, handle_product_purchase: true) }

  before do
    allow(PurchasedNotifier).to receive(:new).and_return(notifier)
  end

  describe "#perform" do
    it "creates notifications for purchased products with sales" do # rubocop:todo RSpec/MultipleExpectations
      described_class.perform_now

      expect(PurchasedNotifier).to have_received(:new)
        .with(purchase_item_ids: [purchase_item_with_sale.id])
      expect(notifier).to have_received(:handle_product_purchase)
    end

    it "does not create notifications for purchased products without sales" do
      described_class.perform_now

      expect(PurchasedNotifier).not_to have_received(:new)
        .with(purchase_item_ids: [purchase_item_without_sale.id])
    end
  end
end
