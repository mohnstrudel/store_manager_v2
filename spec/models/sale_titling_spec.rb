# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale do
  describe "#title" do
    it "returns the status and shop identifier" do
      sale = create(:sale, status: "processing", shopify_name: "HSCM#123")

      expect(sale.title).to eq("Processing | HSCM#123")
    end

    it "falls back to the short Shopify id when the shop name is missing" do
      sale = create(:sale, status: "processing", shopify_name: nil, shopify_id: "gid://shopify/Order/7383283466569")

      expect(sale.title).to eq("Processing | 7383283466569")
    end
  end

  describe "#select_title" do
    it "returns a compact summary for selects" do
      sale = create(:sale, status: "processing", woo_store_id: "woo-123")
      expected_title = "Michele Pomarico | italy_mp@web.de | Processing | woo-123"

      expect(sale.select_title).to eq(expected_title)
    end
  end

  describe "#full_title" do
    it "includes customer name and woo id" do
      sale = create(:sale, woo_store_id: "woo-123")

      expect(sale.full_title).to include("woo-123")
    end

    it "does not raise when the customer is missing" do
      sale = build(:sale, customer: nil, woo_store_id: nil)

      expect(sale.full_title).to eq("")
    end
  end

  describe "#link_title" do
    it "lists the shop identifier, customer name, email and every item title, comma separated" do
      sale = create(:sale, shopify_name: "HSCM#2377")
      first_item = create(:sale_item, sale:, variant: nil)
      second_item = create(:sale_item, sale:, variant: nil)

      expect(sale.reload.link_title).to eq(
        "HSCM#2377, Michele Pomarico, italy_mp@web.de, #{first_item.title}, #{second_item.title}"
      )
    end

    it "uses the record id when the sale has no shop identifier and skips a sale without items" do
      sale = create(:sale, shopify_name: nil, shopify_id: nil, woo_id: nil)
      sale.shopify_info&.destroy
      sale.woo_info&.destroy

      expect(sale.reload.link_title).to eq("#{sale.id}, Michele Pomarico, italy_mp@web.de")
    end
  end
end
