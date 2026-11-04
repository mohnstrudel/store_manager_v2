# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::PullVariantsJob do
  describe "#perform" do
    it "imports the parsed variants for the product" do
      product = create(:product)
      parsed_variants = [{store_id: "gid://shopify/ProductVariant/12345", options: []}]
      allow(Variant::Shopify::Importer).to receive(:import_all!)

      described_class.perform_now(product, parsed_variants)

      expect(Variant::Shopify::Importer).to have_received(:import_all!).with(product, parsed_variants)
    end
  end
end
