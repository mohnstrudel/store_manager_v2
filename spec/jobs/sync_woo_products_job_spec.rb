require "rails_helper"

RSpec.describe SyncWooProductsJob do
  let(:job) {
    described_class.new
  }
  let(:woo_products) { JSON.parse(file_fixture("input_from_api.json").read, symbolize_names: true) }
  let(:parsed_woo_products) { JSON.parse(file_fixture("output_from_parser.json").read, symbolize_names: true) }

  describe "#save_woo_products_to_db" do
    context "when we parsed products from Woo API" do
      it "saves each product to the DB" do
        job.save_woo_products_to_db(parsed_woo_products)
        expect(Product.all.size).to eq(parsed_woo_products.size)
      end
    end
  end

  describe "#parse_woo_products" do
    context "when we receive an array of products from Woo API" do
      it "gives us parsed result" do
        parsed = job.parse_woo_products(woo_products)
        expect(parsed).to eq(parsed_woo_products)
      end
    end
  end
end
