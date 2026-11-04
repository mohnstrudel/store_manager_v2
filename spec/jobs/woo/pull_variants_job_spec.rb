# frozen_string_literal: true

require "rails_helper"

RSpec.describe Woo::PullVariantsJob do
  describe "#perform" do
    it "fetches editions only for products without variants and imports the parsed ones", :aggregate_failures do
      client = instance_double(Woo::Api::Client)
      product_without_variants = create(:product, woo_store_id: "1")
      product_with_variants = create(:product, woo_store_id: "2")
      allow(Product).to receive(:where_woo_ids).with(%w[1 2]).and_return([product_without_variants, product_with_variants])
      allow(product_without_variants).to receive(:variants).and_return(Variant.none)
      allow(product_with_variants).to receive(:variants).and_return([build(:variant)])
      edition = {id: 10, parent_id: 1, attributes: [{name: "Color", option: "Red"}]}
      allow(Woo::Api::Client).to receive(:new).and_return(client)
      allow(client).to receive(:fetch_product_editions).with("1").and_return([edition])
      allow(Variant::Woo::Importer).to receive(:import)

      expect { described_class.new.perform(%w[1 2]) }.to output.to_stderr

      expect(client).not_to have_received(:fetch_product_editions).with("2")
      expect(Variant::Woo::Importer).to have_received(:import).with(Variant::Woo::Parser.parse(edition))
    end
  end
end
