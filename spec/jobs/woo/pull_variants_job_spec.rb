# frozen_string_literal: true

require "rails_helper"

RSpec.describe Woo::PullVariantsJob do
  let(:job) {
    described_class.new
  }
  let(:products_variants) {
    JSON.parse(
      file_fixture("products_variants.json").read,
      symbolize_names: true
    )
  }
  let(:api_variants) {
    JSON.parse(
      file_fixture("api_variants.json").read,
      symbolize_names: true
    )
  }
  let(:pre_parsed_variants) {
    JSON.parse(
      file_fixture("parsed_variants.json").read,
      symbolize_names: true
    )
  }

  describe "#perform" do
    context "when we receive an array of variants from Woo::PullProductsJob" do
      let(:parsed_variants) { job.parse(api_variants) }

      before do
        products_variants.each do |product|
          create(:product, woo_id: product[:woo_id])
        end
      end

      it "test parser" do
        expect(parsed_variants).to eq(pre_parsed_variants)
      end

      it "saves each variant to the DB" do
        expect { job.create(parsed_variants) }.to change(Variant, :count).by(pre_parsed_variants.size)
      end

      it "creates variants with all parsed types" do
        job.create(parsed_variants)

        pre_parsed_variants.each do |variant|
          found_variant = Variant.find_by_woo_id(variant[:woo_id])
          expect(found_variant).not_to be_nil
          expect(found_variant.types_size).to eq(variant[:options].size)
        end
      end

      it "creates variant types with parsed names" do
        job.create(parsed_variants)

        pre_parsed_variants.each do |variant|
          found_variant = Variant.find_by_woo_id(variant[:woo_id])
          expect(found_variant).not_to be_nil
          expect(found_variant.title).to eq(variant[:options].flatten.pluck(:value).sort.join(" | "))
        end
      end
    end
  end
end
