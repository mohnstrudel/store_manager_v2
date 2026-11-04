# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::CreateProductJob do
  describe "#perform" do
    it "creates the product in Shopify" do
      product = create(:product)
      allow(Product).to receive(:find).with(product.id).and_return(product)
      allow(product).to receive(:create_in_shopify_now).and_return(true)

      expect(described_class.perform_now(product.id)).to be true
      expect(product).to have_received(:create_in_shopify_now)
    end

    it "raises when the product does not exist" do
      expect { described_class.perform_now(99999) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
