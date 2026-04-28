# frozen_string_literal: true

require "rails_helper"

RSpec.describe Woo::PullEditionsJob do
  let(:job) {
    described_class.new
  }
  let(:products_editions) {
    JSON.parse(
      file_fixture("products_editions.json").read,
      symbolize_names: true
    )
  }
  let(:api_editions) {
    JSON.parse(
      file_fixture("api_editions.json").read,
      symbolize_names: true
    )
  }
  let(:pre_parsed_editions) {
    JSON.parse(
      file_fixture("parsed_editions.json").read,
      symbolize_names: true
    )
  }

  describe "#perform" do
    context "when we receive an array of variants from Woo::PullProductsJob" do
      let(:parsed_editions) { job.parse(api_editions) }

      before do
        products_editions.each do |product|
          create(:product, woo_id: product[:woo_id])
        end
      end

      it "test parser" do
        expect(parsed_editions).to eq(pre_parsed_editions)
      end

      it "saves each variant to the DB" do
        expect { job.create(parsed_editions) }.to change(Edition, :count).by(pre_parsed_editions.size)
      end

      it "creates editions with all parsed types" do
        job.create(parsed_editions)

        pre_parsed_editions.each do |edition|
          found_edition = Edition.find_by_woo_id(edition[:woo_id])
          expect(found_edition).not_to be_nil
          expect(found_edition.types_size).to eq(edition[:options].size)
        end
      end

      it "creates edition types with parsed names" do
        job.create(parsed_editions)

        pre_parsed_editions.each do |edition|
          found_edition = Edition.find_by_woo_id(edition[:woo_id])
          expect(found_edition).not_to be_nil
          expect(found_edition.title).to eq(edition[:options].flatten.pluck(:value).sort.join(" | "))
        end
      end
    end
  end
end
