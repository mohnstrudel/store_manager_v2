# frozen_string_literal: true

require "rails_helper"

RSpec.describe Variant::Woo::Parser do
  let(:sample_order) {
    JSON.parse(file_fixture("api_orders.json").read, symbolize_names: true).first
  }

  describe ".parse" do
    it "parses variants from the Woo API" do
      api_variants = JSON.parse(file_fixture("api_variants.json").read, symbolize_names: true)
      pre_parsed_variants = JSON.parse(file_fixture("parsed_variants.json").read, symbolize_names: true)

      expect(api_variants.map { described_class.parse(it) }.compact).to eq(pre_parsed_variants)
    end
  end

  describe ".parse_order_line_item" do
    let(:line_item) { sample_order[:line_items].first }

    it "parses variant when found in meta_data" do
      variant = described_class.parse_order_line_item(line_item)

      expect(variant).to be_present
      expect(variant[:options]).to be_present
    end

    it "returns nil when no variant found in meta_data" do
      line_item_without_variant = line_item.merge(meta_data: [])
      variant = described_class.parse_order_line_item(line_item_without_variant)

      expect(variant).to be_nil
    end

    it "includes woo_id when variation_id is present" do
      line_item_with_variation_id = line_item.merge(variation_id: 123)
      variant = described_class.parse_order_line_item(line_item_with_variation_id)

      expect(variant[:woo_id]).to eq(123)
    end
  end
end
