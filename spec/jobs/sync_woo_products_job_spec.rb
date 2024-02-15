require "rails_helper"

RSpec.describe SyncWooProductsJob do
  let(:job) {
    described_class.new
  }
  let(:woo_products) { JSON.parse(file_fixture("api_products.json").read, symbolize_names: true) }
  let(:parsed_products) { JSON.parse(file_fixture("parsed_products.json").read, symbolize_names: true) }

  describe "#parse_all" do
    context "when we receive an array of products from Woo API" do
      it "gives us parsed result" do
        parsed = job.parse_all(woo_products)
        expect(parsed).to eq(parsed_products)
      end
    end
  end

  describe "#get_products_with_variations" do
    it "returns products variations after saving products" do
      expect(job.get_products_with_variations(parsed_products).size).to eq(
        parsed_products
          .map { |p| p[:woo_id] if p[:variations].present? }.compact.size
      )
    end
  end

  describe "#create_all" do
    context "when we parsed products from Woo API" do
      before do
        job.create_all(parsed_products)
      end

      it "saves each product to the DB" do
        expect(Product.all.size).to eq(parsed_products.size)
      end

      it "creates products with all parsed data" do
        first_created = Product.first
        first_parsed = parsed_products.first
        expect(first_created.title).to eq(first_parsed[:title])
        expect(first_created.woo_id).to eq(first_parsed[:woo_id].to_s)
        expect(first_created.shape.title).to eq(first_parsed[:shape])
        expect(first_created.store_link).to eq(first_parsed[:store_link])
        expect(first_created.versions.size).to eq(first_parsed[:versions].size)
        expect(first_created.brands.size).to eq(first_parsed[:brands].size)
        expect(first_created.sizes.size).to eq(first_parsed[:sizes].size)
        expect(first_created.colors.size).to eq(first_parsed[:colors].size)
      end
    end
  end
end
