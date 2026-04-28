# frozen_string_literal: true

require "rails_helper"

RSpec.describe Woo::PullProductsJob do
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

  describe "#get_products_with_variants" do
    it "returns products variants after saving products" do
      expect(job.get_products_with_variants(parsed_products).size).to eq(
        parsed_products
          .map { |p| p[:woo_id] if p[:variants].present? }.compact.size
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

      it "creates products with all parsed data" do # rubocop:todo RSpec/MultipleExpectations
        first_created = Product.first
        first_parsed = parsed_products.first
        expect(first_created.title).to eq(first_parsed[:title])
        expect(first_created.woo_store_id).to eq(first_parsed[:woo_id].to_s)
        expect(first_created.shape).to eq(first_parsed[:shape])
        expect(first_created.woo_info.slug).to eq(first_parsed[:store_link])
        expect(first_created.versions.size).to eq(first_parsed[:versions].size)
        expect(first_created.brands.size).to eq(first_parsed[:brands].size)
        expect(first_created.sizes.size).to eq(first_parsed[:sizes].size)
        expect(first_created.colors.size).to eq(first_parsed[:colors].size)
      end
    end

    context "when a Woo product already exists locally" do
      let(:first_parsed) { parsed_products.first }
      let!(:existing_product) do
        create(:product, woo_store_id: first_parsed[:woo_id], title: "Old Title").tap do |product|
          product.woo_info.update!(slug: nil)
        end
      end

      it "updates the existing product instead of skipping it" do
        expect {
          job.create_all([first_parsed])
        }.not_to change(Product, :count)

        existing_product.reload
        expect(existing_product.title).to eq(first_parsed[:title])
        expect(existing_product.shape).to eq(first_parsed[:shape])
        expect(existing_product.woo_info.store_id).to eq(first_parsed[:woo_id].to_s)
        expect(existing_product.woo_info.slug).to eq(first_parsed[:store_link])
      end
    end
  end
end
