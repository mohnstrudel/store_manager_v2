require "rails_helper"

RSpec.describe SyncWooProductsJob do
  let(:job) {
    described_class.new
  }
  let(:woo_products) { JSON.parse(file_fixture("api_products.json").read, symbolize_names: true) }
  let(:parsed_products) { JSON.parse(file_fixture("parsed_products.json").read, symbolize_names: true) }

  describe "#parse_woo_products" do
    context "when we receive an array of products from Woo API" do
      it "gives us parsed result" do
        parsed = job.parse_woo_products(woo_products)
        expect(parsed).to eq(parsed_products)
      end
    end
  end

  describe "#save_woo_products_to_db" do
    context "when we parsed products from Woo API" do
      before do
        @products_variations = job.save_woo_products_to_db(parsed_products)
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
        expect(first_created.image).to eq(first_parsed[:image])
        expect(first_created.store_link).to eq(first_parsed[:store_link])
        expect(first_created.versions.size).to eq(first_parsed[:versions].size)
        expect(first_created.brands.size).to eq(first_parsed[:brands].size)
        expect(first_created.sizes.size).to eq(first_parsed[:sizes].size)
        expect(first_created.colors.size).to eq(first_parsed[:colors].size)
      end

      it "returns products variations after saving products" do
        expect(@products_variations.size).to eq(
          parsed_products
            .map { |p| p[:woo_id] if p[:variations].present? }.compact.size
        )
      end
    end
  end
end
