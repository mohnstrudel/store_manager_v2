# frozen_string_literal: true

require "rails_helper"

RSpec.describe Edition::Titling do
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
end
