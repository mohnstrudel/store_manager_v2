# frozen_string_literal: true

require "rails_helper"

RSpec.describe Edition::Options do
  describe ".types" do
    it "returns the Woo option-name matrix used for edition mapping" do
      expect(Edition.types).to eq(
        version: ["Version", "Variante"],
        size: ["Size", "Maßstab"],
        color: ["Color", "Farbe"],
        brand: ["Brand", "Marke"]
      )
    end
  end

  describe "#base_model?" do
    context "when edition has no options" do
      let(:edition) { create(:edition, version: nil) }

      it "returns true" do
        expect(edition.base_model?).to be true
      end
    end

    context "when edition has a size" do
      let(:size) { create(:size, value: "1:4") }
      let(:edition) { create(:edition, size:, version: nil) }

      it "returns false" do
        expect(edition.base_model?).to be false
      end
    end

    context "when edition has a version" do
      let(:version) { create(:version, value: "Regular") }
      let(:edition) { create(:edition, version:) }

      it "returns false" do
        expect(edition.base_model?).to be false
      end
    end

    context "when edition has a color" do
      let(:color) { create(:color, value: "Red") }
      let(:edition) { create(:edition, color:, version: nil) }

      it "returns false" do
        expect(edition.base_model?).to be false
      end
    end
  end

  describe "type helpers" do
    let(:edition) do
      create(
        :edition,
        size: create(:size, value: "1:6"),
        version: create(:version, value: "DX"),
        color: create(:color, value: "Black")
      )
    end

    it "returns type names list" do
      expect(edition.types).to eq(["Size", "Version", "Color"])
    end

    it "returns a human readable type-name line" do
      expect(edition.types_name).to eq("Size | Version | Color")
    end

    it "returns the count of present types" do
      expect(edition.types_size).to eq(3)
    end

    it "returns type names with values" do
      expect(edition.type_name_and_value).to eq("Size: 1:6, Version: DX, Color: Black")
    end
  end
end
