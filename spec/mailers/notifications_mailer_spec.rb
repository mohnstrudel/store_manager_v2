require "rails_helper"

RSpec.describe NotificationsMailer do
  describe "#product_purchased_email" do
    let(:mail) {
      described_class.product_purchased_email(
        customer_name: "John Doe",
        email: "john@example.com",
        item_name: "Test Item",
        order_number: "123",
        warehouse_name: "Test Warehouse",
        warehouse_desc_en: "English description for Test Warehouse",
        warehouse_desc_de: "German description for Test Warehouse"
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
      expect(mail.body.encoded).to match("English description for Test Warehouse")
      expect(mail.body.encoded).to match("German description for Test Warehouse")
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
        to_warehouse: "New Warehouse",
        tracking_number: "ABC123",
        tracking_url: "https://example.com/tracking",
        previous_status_desc_en: "English description for Old Warehouse",
        previous_status_desc_de: "German description for Old Warehouse",
        new_status_desc_en: "English description for New Warehouse",
        new_status_desc_de: "German description for New Warehouse"
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
      expect(mail.body.encoded).to match("English description for Old Warehouse")
      expect(mail.body.encoded).to match("German description for Old Warehouse")
      expect(mail.body.encoded).to match("English description for New Warehouse")
      expect(mail.body.encoded).to match("German description for New Warehouse")
    end
  end
end
