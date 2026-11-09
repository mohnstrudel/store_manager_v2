# frozen_string_literal: true

require "rails_helper"

RSpec.describe Variant::Woo::Parser do
  let(:sample_order) {
    JSON.parse(file_fixture("api_orders.json").read, symbolize_names: true).first
  }

  describe ".parse_order_line_item" do
    let(:line_item) { sample_order[:line_items].first }

    it "parses variant when found in meta_data" do
      variant = described_class.parse_order_line_item(line_item)

      expect(variant).to be_present
      expect(variant[:options]).to be_present
    end

    it "returns nil when no variant found in meta_data" do
      line_item_without_variant = line_item.merge(meta_data: [], variation_id: 0)
      variant = described_class.parse_order_line_item(line_item_without_variant)

      expect(variant).to be_nil
    end

    it "includes woo_id when variation_id is present" do
      line_item_with_variation_id = line_item.merge(variation_id: 123)
      variant = described_class.parse_order_line_item(line_item_with_variation_id)

      expect(variant[:woo_id]).to eq(123)
    end

    context "when a line has a positive variation_id and no recognized options" do
      let(:line_item_with_known_variation) do
        line_item.merge(
          variation_id: 14079,
          product_id: 11,
          meta_data: [
            {id: 1, key: "pa_preistyp", value: "voller-preis", display_key: "Preistyp", display_value: "Voller Preis"},
            {id: 2, key: "stock_status", value: "instock", display_key: "Stock Status", display_value: "In stock"}
          ]
        )
      end

      it "returns the variation with no options" do
        expect(described_class.parse_order_line_item(line_item_with_known_variation)).to eq(
          {woo_id: 14079, product_woo_id: 11, options: []}
        )
      end

      it "returns nil when variation_id is zero" do
        expect(described_class.parse_order_line_item(line_item_with_known_variation.merge(variation_id: 0))).to be_nil
      end
    end
  end
end
