# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::CreateOptionsAndVariantsJob do
  describe "#perform" do
    it "pushes the product options to Shopify" do
      allow(Product::Shopify::OptionsPush).to receive(:call).and_return(true)

      described_class.perform_now(42, "gid://shopify/Product/12345")

      expect(Product::Shopify::OptionsPush).to have_received(:call)
        .with(product_id: 42, product_store_id: "gid://shopify/Product/12345")
    end
  end
end
