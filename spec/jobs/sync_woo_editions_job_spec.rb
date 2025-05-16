require "rails_helper"

RSpec.describe SyncWooEditionsJob do
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
  let(:parsed_editions) {
    JSON.parse(
      file_fixture("parsed_editions.json").read,
      symbolize_names: true
    )
  }

  describe "#perform" do
    context "when we receive an array of variants from SyncWooProductsJob" do
      before do
        products_editions.each do |product|
          create(:product, woo_id: product[:woo_id])
        end
      end

      it "test parser" do
        parsed = job.parse(api_editions)
        expect(parsed).to eq(parsed_editions)
      end

      it "saves each variant to the DB" do
        job.create(parsed_editions)
        expect(Edition.all.size).to eq(parsed_editions.size)
      end

      it "creates editions with all parsed types" do
        job.create(parsed_editions)

        parsed_editions.each do |edition|
          expect(Edition.find_by(woo_id: edition[:woo_id]).types_size).to eq(edition[:editions].size)
        end
      end

      it "creates edition types with parsed names" do
        job.create(parsed_editions)

        parsed_editions.each do |edition|
          expect(Edition.find_by(woo_id: edition[:woo_id]).title).to eq(edition[:editions].flatten.pluck(:value).sort.join(" | "))
        end
      end
    end
  end
end
