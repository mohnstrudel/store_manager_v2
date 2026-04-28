# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale do
  describe "#title" do
    it "returns the status and shop identifier" do
      sale = create(:sale, status: "processing", shopify_name: "HSCM#123")

      expect(sale.title).to eq("Processing | HSCM#123")
    end
  end

  describe "#select_title" do
    it "returns a compact summary for selects" do
      sale = create(:sale, status: "processing", woo_store_id: "woo-123")
      expected_title = "Michele Pomarico | italy_mp@web.de | Processing | woo-123"

      expect(sale.select_title).to eq(expected_title)
    end
  end

  describe "#created_at_for_display" do
    it "returns woo_created_at when present" do
      sale = create(:sale, woo_created_at: 2.days.ago)

      expect(sale.created_at_for_display).to be_within(1.second).of(2.days.ago)
    end
  end

  describe "#full_title" do
    it "includes customer name and woo id" do
      sale = create(:sale, woo_store_id: "woo-123")

      expect(sale.full_title).to include("woo-123")
    end
  end
end
