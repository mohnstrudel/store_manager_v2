require "rails_helper"

RSpec.describe NotificationsMailer do
  describe "#product_purchased_email" do
    let(:mail) {
      described_class.product_purchased_email(
        customer_name: "John Doe",
        email: "john@example.com",
        item_name: "Test Item",
        order_number: "123",
        warehouse_name_en: "Test Warehouse EN",
        warehouse_name_de: "Test Lager DE",
        warehouse_desc_en: "English description for Test Warehouse",
        warehouse_desc_de: "German description for Test Warehouse"
      )
    }

    it "renders headers" do
      expect(mail.subject).to include("Test Warehouse EN")
      expect(mail.to).to eq(["john@example.com"])
      expect(mail.from).to eq(["store@handsomecake.com"])
    end

    it "renders body" do
      expect(mail.body.encoded).to match("Hello John Doe")
      expect(mail.body.encoded).to match("Test Warehouse EN")
      expect(mail.body.encoded).to match("Test Lager DE")
      expect(mail.body.encoded).to match("123")
      expect(mail.body.encoded).to match("English description for Test Warehouse")
      expect(mail.body.encoded).to match("German description for Test Warehouse")
    end

    it "does not contain internal warehouse name" do
      expect(mail.body.encoded).not_to match(/warehouse_name/i)
      expect(mail.subject).not_to match(/warehouse_name/i)
    end
  end

  describe "#warehouse_changed_email" do
    let(:mail) {
      described_class.warehouse_changed_email(
        customer_name: "John Doe",
        email: "john@example.com",
        item_name: "Test Item",
        order_number: "123",
        from_warehouse_name_en: "Old Warehouse EN",
        from_warehouse_name_de: "Altes Lager DE",
        to_warehouse_name_en: "New Warehouse EN",
        to_warehouse_name_de: "Neues Lager DE",
        tracking_number: "ABC123",
        tracking_url: "https://example.com/tracking",
        new_status_desc_en: "English description for New Warehouse",
        new_status_desc_de: "German description for New Warehouse"
      )
    }

    it "renders headers" do
      expect(mail.subject).to include("Old Warehouse EN")
      expect(mail.subject).to include("New Warehouse EN")
      expect(mail.to).to eq(["john@example.com"])
      expect(mail.from).to eq(["store@handsomecake.com"])
    end

    it "renders body" do
      expect(mail.body.encoded).to match("Hello John Doe")
      expect(mail.body.encoded).to match("Old Warehouse EN")
      expect(mail.body.encoded).to match("Altes Lager DE")
      expect(mail.body.encoded).to match("New Warehouse EN")
      expect(mail.body.encoded).to match("Neues Lager DE")
      expect(mail.body.encoded).to match("123")
      expect(mail.body.encoded).to match("English description for New Warehouse")
      expect(mail.body.encoded).to match("German description for New Warehouse")
    end

    it "does not contain previous status descriptions" do
      expect(mail.body.encoded).not_to match(/previous.*description|old.*description|from.*description/i)
      expect(mail.subject).not_to match(/previous.*description|old.*description|from.*description/i)
    end

    it "does not contain internal warehouse name" do
      expect(mail.body.encoded).not_to match(/from_warehouse|to_warehouse|new_status/i)
      expect(mail.subject).not_to match(/from_warehouse|to_warehouse|new_status/i)
    end
  end
end
