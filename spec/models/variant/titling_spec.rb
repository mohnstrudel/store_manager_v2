# frozen_string_literal: true

require "rails_helper"

RSpec.describe Variant::Titling do
  describe "#title" do
    context "when variant has sizes" do
      let(:first_size) { "1:4" }
      let(:second_size) { "1:6" }
      let(:variant_one) { create(:variant, :with_size, size_value: first_size) }
      let(:variant_two) { create(:variant, :with_size, size_value: second_size) }

      it "title includes 1:4" do
        expect(variant_one.title).to include(first_size)
      end

      it "title includes 1:6" do
        expect(variant_two.title).to include(second_size)
      end
    end

    context "when variant has versions" do
      let(:first_version) { "Regular Armor" }
      let(:second_version) { "Revealing Armor" }
      let(:variant_one) { create(:variant, :with_version, version_value: first_version) }
      let(:variant_two) { create(:variant, :with_version, version_value: second_version) }

      it "title includes first version value" do
        expect(variant_one.title).to include(first_version)
      end

      it "title includes second version value" do
        expect(variant_two.title).to include(second_version)
      end
    end

    context "when variant has colors" do
      let(:first_color) { "Blau" }
      let(:second_color) { "Grau" }
      let(:variant_one) { create(:variant, :with_color, color_value: first_color) }
      let(:variant_two) { create(:variant, :with_color, color_value: second_color) }

      it "title includes first color value" do
        expect(variant_one.title).to include(first_color)
      end

      it "title includes second color value" do
        expect(variant_two.title).to include(second_color)
      end
    end

    context "when variant has no options (Base Model)" do
      let(:variant) { create(:product).base_variant }

      it "returns Base Model" do
        expect(variant.title).to eq("Base Model")
      end
    end

    context "when variant has multiple options" do
      let(:size) { create(:size, value: "1:4") }
      let(:version) { create(:version, value: "Regular") }
      let(:color) { create(:color, value: "Red") }
      let(:variant) { create(:variant, size:, version:, color:) }

      it "joins all options with separators" do
        expect(variant.title).to eq("1:4 | Regular | Red")
      end
    end
  end
end
