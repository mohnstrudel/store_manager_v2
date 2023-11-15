require "rails_helper"

RSpec.describe SyncWooProductsJob do
  describe "#map_woo_products_to_model" do
    context "when we received an array of products from WooCommerce" do
      let(:woo_products) { JSON.parse(file_fixture("input_from_api.json").read, symbolize_names: true) }
      let(:result) { JSON.parse(file_fixture("output_from_parser.json").read, symbolize_names: true) }
      let(:job) { described_class.new }

      it "gives us parsed result" do
        parsed = job.map_woo_products_to_model(woo_products)
        expect(parsed).to eq(result)
      end
    end
  end
end
