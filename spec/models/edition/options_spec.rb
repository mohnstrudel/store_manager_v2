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

  describe "#title" do
    context "when edition has sizes" do
      let(:first_size) { "1:4" }
      let(:second_size) { "1:6" }
      let(:edition_one) { create(:edition, :with_size, size_value: first_size) }
      let(:edition_two) { create(:edition, :with_size, size_value: second_size) }

      it "title includes 1:4" do
        expect(edition_one.title).to include(first_size)
      end

      it "title includes 1:6" do
        expect(edition_two.title).to include(second_size)
      end
    end

    context "when edition has versions" do
      let(:first_version) { "Regular Armor" }
      let(:second_version) { "Revealing Armor" }
      let(:edition_one) { create(:edition, :with_version, version_value: first_version) }
      let(:edition_two) { create(:edition, :with_version, version_value: second_version) }

      it "title includes first version value" do
        expect(edition_one.title).to include(first_version)
      end

      it "title includes second version value" do
        expect(edition_two.title).to include(second_version)
      end
    end

    context "when edition has colors" do
      let(:first_color) { "Blau" }
      let(:second_color) { "Grau" }
      let(:edition_one) { create(:edition, :with_color, color_value: first_color) }
      let(:edition_two) { create(:edition, :with_color, color_value: second_color) }

      it "title includes first color value" do
        expect(edition_one.title).to include(first_color)
      end

      it "title includes second color value" do
        expect(edition_two.title).to include(second_color)
      end
    end

    context "when edition has no options (Base Model)" do
      let(:edition) { create(:edition, version: nil) }

      it "returns Base Model" do
        expect(edition.title).to eq("Base Model")
      end
    end

    context "when edition has multiple options" do
      let(:size) { create(:size, value: "1:4") }
      let(:version) { create(:version, value: "Regular") }
      let(:color) { create(:color, value: "Red") }
      let(:edition) { create(:edition, size:, version:, color:) }

      it "joins all options with separators" do
        expect(edition.title).to eq("1:4 | Regular | Red")
      end
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
