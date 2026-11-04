# frozen_string_literal: true

require "rails_helper"

RSpec.describe Variant::Woo::Importer do
  let(:products_variants) { JSON.parse(file_fixture("products_variants.json").read, symbolize_names: true) }
  let(:api_variants) { JSON.parse(file_fixture("api_variants.json").read, symbolize_names: true) }
  let(:pre_parsed_variants) { JSON.parse(file_fixture("parsed_variants.json").read, symbolize_names: true) }
  let(:parsed_variants) { api_variants.map { Variant::Woo::Parser.parse(it) }.compact }

  before do
    products_variants.each do |product|
      create(:product, woo_id: product[:woo_id])
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
  end
end
