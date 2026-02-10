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

  describe ".with_shopify_variant" do
    let(:edition_with_variant) { create(:edition) }
    let(:edition_without_variant) { create(:edition, shopify_id: nil) }

    it "includes editions with shopify_id" do
      expect(described_class.with_shopify_variant).to include(edition_with_variant)
      expect(described_class.with_shopify_variant).not_to include(edition_without_variant)
    end
  end

  describe ".without_shopify_variant" do
    let(:edition_with_variant) { create(:edition) }
    let(:edition_without_variant) { create(:edition, shopify_id: nil) }

    it "includes editions without shopify_id" do
      expect(described_class.without_shopify_variant).to include(edition_without_variant)
      expect(described_class.without_shopify_variant).not_to include(edition_with_variant)
    end
  end

  describe ".from_shopify_variant" do
    let(:product) { create(:product) }
    let(:variant_data) do
      {
        id: "gid://shopify/ProductVariant/123456789",
        title: "1:4 | Regular | Red",
        options: [
          {name: "Size", value: "1:4"},
          {name: "Version", value: "Regular"},
          {name: "Color", value: "Red"}
        ],
        store_info: {
          ext_created_at: 1.day.ago,
          ext_updated_at: 1.hour.ago
        }
      }
    end

    context "with valid variant data" do
      it "creates a new edition with parsed options" do
        edition = described_class.from_shopify_variant(product, variant_data)

        expect(edition).to be_persisted
        expect(edition.product).to eq(product)
        expect(edition.size.value).to eq("1:4")
        expect(edition.version.value).to eq("Regular")
        expect(edition.color.value).to eq("Red")
      end

      it "associates parsed options with the product" do
        described_class.from_shopify_variant(product, variant_data)

        expect(product.sizes.pluck(:value)).to include("1:4")
        expect(product.versions.pluck(:value)).to include("Regular")
        expect(product.colors.pluck(:value)).to include("Red")
      end

      it "updates Shopify store info" do
        edition = described_class.from_shopify_variant(product, variant_data)
        edition.reload

        expect(edition.shopify_info).to be_present
        expect(edition.shopify_info.store_id).to eq(variant_data[:id])
        expect(edition.shopify_info.ext_created_at).to be_within(1.second).of(variant_data[:store_info][:ext_created_at])
      end
    end

    context "with existing edition" do
      let(:existing_edition) { create(:edition, product:, shopify_id: variant_data[:id]) }

      before do
        existing_edition
      end

      it "updates the existing edition" do
        edition = described_class.from_shopify_variant(product, variant_data)

        expect(edition.id).to eq(existing_edition.id)
      end
    end

    context "with blank options" do
      it "returns nil" do
        result = described_class.from_shopify_variant(product, options: [])

        expect(result).to be_nil
      end
    end

    context "with Scale option name" do
      let(:scale_variant_data) do
        {
          id: "gid://shopify/ProductVariant/987654321",
          options: [
            {name: "Scale", value: "1:6"}
          ]
        }
      end

      it "parses Scale as Size" do
        edition = described_class.from_shopify_variant(product, scale_variant_data)

        expect(edition.size.value).to eq("1:6")
      end
    end

    context "with Edition option name" do
      let(:edition_variant_data) do
        {
          id: "gid://shopify/ProductVariant/111111111",
          options: [
            {name: "Edition", value: "Limited"}
          ]
        }
      end

      it "parses Edition as Version" do
        edition = described_class.from_shopify_variant(product, edition_variant_data)

        expect(edition.version.value).to eq("Limited")
      end
    end
  end

  describe "#sync_variant_options!" do
    let(:edition) { create(:edition) }
    let(:options_data) do
      [
        {name: "Color", value: "Blue"},
        {name: "Size", value: "1:6"},
        {name: "Version", value: "Limited"}
      ]
    end

    context "with valid options data" do
      it "creates and assigns variant options" do
        edition.sync_variant_options!(options_data)

        expect(edition.color.value).to eq("Blue")
        expect(edition.size.value).to eq("1:6")
        expect(edition.version.value).to eq("Limited")
      end

      it "associates new options with the product" do
        product = edition.product
        edition.sync_variant_options!(options_data)

        expect(product.colors.pluck(:value)).to include("Blue")
        expect(product.sizes.pluck(:value)).to include("1:6")
        expect(product.versions.pluck(:value)).to include("Limited")
      end

      it "saves the edition" do
        expect {
          edition.sync_variant_options!(options_data)
        }.to change { edition.reload.color_id }.from(nil)
      end
    end

    context "with blank options data" do
      it "does not modify the edition" do
        original_attributes = edition.attributes
        edition.sync_variant_options!([])

        expect(edition.attributes).to eq(original_attributes)
      end
    end

    context "with Scale option name" do
      let(:scale_options) { [{name: "Scale", value: "1:3"}] }

      it "assigns scale to size" do
        edition.sync_variant_options!(scale_options)

        expect(edition.size.value).to eq("1:3")
      end
    end

    context "with Variante option name" do
      let(:variante_options) { [{name: "Variante", value: "Deluxe"}] }

      it "assigns variante to version" do
        edition.sync_variant_options!(variante_options)

        expect(edition.version.value).to eq("Deluxe")
      end
    end
  end
end
