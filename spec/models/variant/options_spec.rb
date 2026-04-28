# frozen_string_literal: true

require "rails_helper"

RSpec.describe Variant::Options do
  describe ".types" do
    it "returns the Woo option-name matrix used for variant mapping" do
      expect(Variant.types).to eq(
        version: ["Version", "Variante"],
        size: ["Size", "Maßstab"],
        color: ["Color", "Farbe"],
        brand: ["Brand", "Marke"]
      )
    end
  end

  describe "#base_model?" do
    context "when variant has no options" do
      let(:variant) { create(:product).base_variant }

      it "returns true" do
        expect(variant.base_model?).to be true
      end
    end

    context "when variant has a size" do
      let(:size) { create(:size, value: "1:4") }
      let(:variant) { create(:variant, size:, version: nil) }

      it "returns false" do
        expect(variant.base_model?).to be false
      end
    end

    context "when variant has a version" do
      let(:version) { create(:version, value: "Regular") }
      let(:variant) { create(:variant, version:) }

      it "returns false" do
        expect(variant.base_model?).to be false
      end
    end

    context "when variant has a color" do
      let(:color) { create(:color, value: "Red") }
      let(:variant) { create(:variant, color:, version: nil) }

      it "returns false" do
        expect(variant.base_model?).to be false
      end
    end
  end

  describe "type helpers" do
    let(:variant) do
      create(
        :variant,
        size: create(:size, value: "1:6"),
        version: create(:version, value: "DX"),
        color: create(:color, value: "Black")
      )
    end

    it "returns type names list" do
      expect(variant.types).to eq(["Size", "Version", "Color"])
    end

    it "returns a human readable type-name line" do
      expect(variant.types_name).to eq("Size | Version | Color")
    end

    it "returns the count of present types" do
      expect(variant.types_size).to eq(3)
    end

    it "returns type names with values" do
      expect(variant.type_name_and_value).to eq("Size: 1:6, Version: DX, Color: Black")
    end
  end
end
