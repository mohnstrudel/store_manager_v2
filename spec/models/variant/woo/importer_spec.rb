# frozen_string_literal: true

require "rails_helper"

RSpec.describe Variant::Woo::Importer do
  let(:products_variants) { JSON.parse(file_fixture("products_variants.json").read, symbolize_names: true) }
  let(:pre_parsed_variants) { JSON.parse(file_fixture("parsed_variants.json").read, symbolize_names: true) }
  let(:parsed_variants) { pre_parsed_variants }

  before do
    products_variants.each do |product|
      create(:product, :synced, woo_id: product[:woo_id])
    end
  end

  describe ".import" do
    it "saves each variant to the DB" do
      expect { parsed_variants.each { described_class.import(it) } }.to change(Variant, :count).by(pre_parsed_variants.size)
    end

    it "creates variants with all parsed types" do
      parsed_variants.each { described_class.import(it) }

      pre_parsed_variants.each do |variant|
        found_variant = Variant.find_by_woo_id(variant[:woo_id])
        expect(found_variant).not_to be_nil
        expect(found_variant.types_size).to eq(variant[:options].size)
      end
    end

    it "creates variant types with parsed names" do
      parsed_variants.each { described_class.import(it) }

      pre_parsed_variants.each do |variant|
        found_variant = Variant.find_by_woo_id(variant[:woo_id])
        expect(found_variant).not_to be_nil
        expect(found_variant.title).to eq(variant[:options].flatten.pluck(:value).sort.join(" | "))
      end
    end

    context "when the parsed variant has no options" do
      let(:product) { create(:product, woo_store_id: "woo-product") }
      let(:parsed_variant) { {woo_id: "14079", product_woo_id: "woo-product", options: []} }

      before { create(:variant, :with_version, product:) }

      it "returns the variant of the same product with that Woo id" do
        known_variant = create(:variant, :with_version, product:, woo_store_id: "14079")

        expect(described_class.import(parsed_variant)).to eq(known_variant)
      end

      it "ignores a variant of another product with that Woo id" do
        create(:variant, :with_version, product: create(:product), woo_store_id: "14079")

        expect(described_class.import(parsed_variant)).to be_nil
      end

      it "builds nothing for an unknown Woo id", :aggregate_failures do
        expect { expect(described_class.import(parsed_variant)).to be_nil }.not_to change(Variant, :count)
      end

      it "does not match any variant of the product without a Woo id", :aggregate_failures do
        expect { expect(described_class.import(parsed_variant.merge(woo_id: nil))).to be_nil }.not_to change(Variant, :count)
      end
    end
  end
end
