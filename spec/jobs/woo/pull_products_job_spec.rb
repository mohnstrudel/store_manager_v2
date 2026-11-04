# frozen_string_literal: true

require "rails_helper"

RSpec.describe Woo::PullProductsJob do
  describe "#perform" do
    it "imports every parsed product and returns the Woo ids that have variants", :aggregate_failures do
      client = instance_double(Woo::Api::Client)
      woo_products = [{id: 1}, {id: 2}]
      parsed_products = [{woo_id: 1, variants: [10]}, {woo_id: 2, variants: []}]
      allow(Woo::Api::Client).to receive(:new).and_return(client)
      allow(client).to receive(:fetch_products).with(described_class::PRODUCTS_SIZE).and_return(woo_products)
      allow(Product::Woo::Parser).to receive(:parse_all).with(woo_products).and_return(parsed_products)
      allow(Product::Woo::Importer).to receive(:import!)

      expect(described_class.new.perform).to eq([1])

      expect(Product::Woo::Importer).to have_received(:import!).with(parsed_products.first)
      expect(Product::Woo::Importer).to have_received(:import!).with(parsed_products.last)
    end
  end
end
