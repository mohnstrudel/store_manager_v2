# frozen_string_literal: true

# == Schema Information
#
# Table name: editions
#
#  id         :bigint           not null, primary key
#  sku        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  color_id   :bigint
#  product_id :bigint           not null
#  shopify_id :string
#  size_id    :bigint
#  version_id :bigint
#  woo_id     :string
#
require "rails_helper"

RSpec.describe Edition do
  describe "#title" do
    context "when edition has sizes" do
      sizes = ["1:4", "1:6"]
      let(:edition_one) { create(:edition, :with_size, size_value: sizes.first) }
      let(:edition_two) { create(:edition, :with_size, size_value: sizes.last) }

      it "title includes #{sizes.first}" do
        expect(edition_one.title).to include(sizes.first)
      end

      it "title includes #{sizes.last}" do
        expect(edition_two.title).to include(sizes.last)
      end
    end

    context "when edition has versions" do
      versions = ["Regular Armor", "Revealing Armor"]
      let(:edition_one) { create(:edition, :with_version, version_value: versions.first) }
      let(:edition_two) { create(:edition, :with_version, version_value: versions.last) }

      it "title includes #{versions.first}" do
        expect(edition_one.title).to include(versions.first)
      end

      it "title includes #{versions.last}" do
        expect(edition_two.title).to include(versions.last)
      end
    end

    context "when edition has colors" do
      colors = ["Blau", "Grau"]
      let(:edition_one) { create(:edition, :with_color, color_value: colors.first) }
      let(:edition_two) { create(:edition, :with_color, color_value: colors.last) }

      it "title includes #{colors.first}" do
        expect(edition_one.title).to include(colors.first)
      end

      it "title includes #{colors.last}" do
        expect(edition_two.title).to include(colors.last)
      end
    end

    context "when edition has no options (Base Model)" do
      let(:edition) { create(:edition, version: nil) }

      it "returns 'Base Model'" do
        expect(edition.title).to eq("Base Model")
      end
    end

    context "when edition has multiple options" do
      let(:size) { create(:size, value: "1:4") }
      let(:version) { create(:version, value: "Regular") }
      let(:color) { create(:color, value: "Red") }
      let(:edition) { create(:edition, size:, version:, color:) }

      it "joins all options with ' | '" do
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

  describe "price" do
    it "returns 0.0 since price tracking was removed from StoreInfo" do
      edition = create(:edition)
      expect(edition.price).to eq(0.0)
    end
  end

  describe "auditing" do
    it "is audited" do
      expect(described_class.auditing_enabled).to be true
    end
  end
end
