require "rails_helper"

RSpec.describe NotificationsMailer do
  describe "#product_purchased_email" do
    let(:mail) {
      described_class.product_purchased_email(
        customer_name: "John Doe",
        email: "john@example.com",
        item_name: "Test Item",
        order_number: "123",
        warehouse_name: "Test Warehouse"
      )
    }

    it "renders headers" do
      expect(mail.subject).to include("Test Warehouse")
      expect(mail.to).to eq(["john@example.com"])
      expect(mail.from).to eq(["store@handsomecake.com"])
    end

    it "renders body" do
      expect(mail.body.encoded).to match("Hello John Doe")
      expect(mail.body.encoded).to match("Test Warehouse")
      expect(mail.body.encoded).to match("123")
    end
  end

  describe "#warehouse_changed_email" do
    let(:mail) {
      described_class.warehouse_changed_email(
        customer_name: "John Doe",
        email: "john@example.com",
        from_warehouse: "Old Warehouse",
        item_name: "Test Item",
        order_number: "123",
        to_warehouse: "New Warehouse"
      )
    }

    it "renders headers" do
      expect(mail.subject).to include("Old Warehouse")
      expect(mail.subject).to include("New Warehouse")
      expect(mail.to).to eq(["john@example.com"])
      expect(mail.from).to eq(["store@handsomecake.com"])
    end

    it "renders body" do
      expect(mail.body.encoded).to match("Hello John Doe")
      expect(mail.body.encoded).to match("Old Warehouse")
      expect(mail.body.encoded).to match("New Warehouse")
      expect(mail.body.encoded).to match("123")
    end
  end
end
