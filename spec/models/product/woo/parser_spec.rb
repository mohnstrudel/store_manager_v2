# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Woo::Parser do
  let(:woo_products) { JSON.parse(file_fixture("api_products.json").read, symbolize_names: true) }
  let(:parsed_products) { JSON.parse(file_fixture("parsed_products.json").read, symbolize_names: true) }

  describe ".parse_all" do
    it "parses an array of products from the Woo API" do
      expect(described_class.parse_all(woo_products)).to eq(parsed_products)
    end
  end

  describe ".parse" do
    it "returns nil when Woo returns no product" do
      expect(described_class.parse(nil)).to be_nil
    end
  end
end
