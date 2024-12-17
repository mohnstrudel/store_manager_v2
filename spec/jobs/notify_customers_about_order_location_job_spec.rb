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
  let(:notification_service) {
    class_spy(Notification).tap do |spy|
      allow(spy).to receive(:event_types).and_return({product_purchased: 0})
    end
  }

  before do
    stub_const("Notification", notification_service)
  end

  describe "#perform" do
    it "creates notifications for purchased products with sales" do
      described_class.perform_now

      expect(notification_service).to have_received(:dispatch).with(
        event: Notification.event_types[:product_purchased],
        context: {purchased_product_id: purchased_product_with_sale.id}
      )
    end

    it "does not create notifications for purchased products without sales" do
      described_class.perform_now

      expect(notification_service).not_to have_received(:dispatch).with(
        event: Notification.event_types[:product_purchased],
        context: {purchased_product_id: purchased_product_without_sale.id}
      )
    end
  end
end
