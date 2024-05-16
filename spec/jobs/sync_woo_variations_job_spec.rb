require "rails_helper"

RSpec.describe SyncWooVariationsJob do
  let(:job) {
    described_class.new
  }
  let(:products_variations) {
    JSON.parse(
      file_fixture("products_variations.json").read,
      symbolize_names: true
    )
  }
  let(:api_variations) {
    JSON.parse(
      file_fixture("api_variations.json").read,
      symbolize_names: true
    )
  }
  let(:parsed_variations) {
    JSON.parse(
      file_fixture("parsed_variations.json").read,
      symbolize_names: true
    )
  }

  describe "#perform" do
    context "when we receive an array of variants from SyncWooProductsJob" do
      before do
        products_variations.each do |product|
          create(:product, woo_id: product[:woo_id])
        end
      end

      it "test parser" do
        parsed = job.parse(api_variations)
        expect(parsed).to eq(parsed_variations)
      end

      it "saves each variant to the DB" do
        job.create(parsed_variations)
        expect(Variation.all.size).to eq(parsed_variations.size)
      end

      it "creates variations with all parsed types" do
        job.create(parsed_variations)

        parsed_variations.each do |variation|
          expect(Variation.find_by(woo_id: variation[:woo_id]).types_size).to eq(variation[:variations].size)
        end
      end

      it "creates variation types with parsed names" do
        job.create(parsed_variations)

        parsed_variations.each do |variation|
          expect(Variation.find_by(woo_id: variation[:woo_id]).title).to eq(variation[:variations].flatten.pluck(:value).sort.join(" | "))
        end
      end
    end
  end
end
