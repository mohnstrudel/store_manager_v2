# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Woo::Parser do
  let(:woo_products) { JSON.parse(file_fixture("api_products.json").read, symbolize_names: true) }
  let(:parsed_products) { JSON.parse(file_fixture("parsed_products.json").read, symbolize_names: true) }

  describe "ATTRIBUTE_NAMES" do
    it "holds the Woo option-name matrix used for variant mapping" do
      expect(described_class::ATTRIBUTE_NAMES).to eq(
        version: ["Version", "Variante"],
        size: ["Size", "Maßstab"],
        color: ["Color", "Farbe"],
        brand: ["Brand", "Marke"]
      )
    end
  end

  describe ".parse" do
    it "parses products from the Woo API" do
      expect(woo_products.map { described_class.parse(it) }.compact_blank).to eq(parsed_products)
    end

    it "returns nil when Woo returns no product" do
      expect(described_class.parse(nil)).to be_nil
    end
  end
end
