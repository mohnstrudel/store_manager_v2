# frozen_string_literal: true
# == Schema Information
#
# Table name: editions
#
#  id         :bigint           not null, primary key
#  sku        :string
#  store_link :string
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
  end

  describe "price" do
    it "returns the price from Shopify StoreInfo" do
      edition = create(:edition)
      create(:store_info, :shopify, storable: edition, price: 19.99)
      expect(edition.price).to eq(19.99)
    end

    it "returns 0.0 when no Shopify StoreInfo exists" do
      edition = create(:edition)
      expect(edition.price).to eq(0.0)
    end

    it "handles integer prices" do
      edition = create(:edition)
      create(:store_info, :shopify, storable: edition, price: 25)
      expect(edition.price).to eq(25.0)
    end

    it "handles decimal precision correctly" do
      edition = create(:edition)
      create(:store_info, :shopify, storable: edition, price: 123.456)
      expect(edition.price).to eq(123.46)
    end
  end

  describe "auditing" do
    it "is audited" do
      expect(described_class.auditing_enabled).to be true
    end
  end
end
