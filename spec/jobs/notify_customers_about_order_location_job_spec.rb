require "rails_helper"

RSpec.describe NotifyCustomersAboutOrderLocationJob do
  let(:warehouse) { create(:warehouse) }
  let(:purchase) { create(:purchase) }
  let!(:purchased_product_with_sale) do
    create(:purchased_product,
      warehouse:,
      purchase:,
      product_sale: create(:product_sale, sale: create(:sale)))
  end
  let!(:purchased_product_without_sale) do
    create(:purchased_product,
      warehouse:,
      purchase:,
      product_sale: nil)
  end

  let(:notifier) { instance_double(Notifier, handle_product_purchase: true) }

  before do
    allow(Notifier).to receive(:new).and_return(notifier)
  end

  describe "#perform" do
    it "creates notifications for purchased products with sales" do
      described_class.perform_now

      expect(Notifier).to have_received(:new)
        .with(purchased_product_ids: [purchased_product_with_sale.id])
      expect(notifier).to have_received(:handle_product_purchase)
    end

    it "does not create notifications for purchased products without sales" do
      described_class.perform_now

      expect(Notifier).not_to have_received(:new)
        .with(purchased_product_ids: [purchased_product_without_sale.id])
    end
  end
end
