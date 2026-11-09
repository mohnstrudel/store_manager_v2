# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::UpdateProductJob do
  include ActiveJob::TestHelper

  describe "#perform" do
    it "updates the product in Shopify" do
      product = create(:product)
      allow(Product).to receive(:find).with(product.id).and_return(product)
      allow(product).to receive(:update_in_shopify_now).and_return(true)

      expect(described_class.perform_now(product.id)).to be true
      expect(product).to have_received(:update_in_shopify_now)
    end

    it "raises when the product does not exist" do
      expect { described_class.perform_now(99999) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "re-enqueues the job with the same product id when Shopify throttles the update" do
      product = create(:product)
      allow(Product).to receive(:find).with(product.id).and_return(product)
      allow(product).to receive(:update_in_shopify_now).and_raise(Shopify::Api::Client::Throttled)

      expect { described_class.perform_now(product.id) }.to have_enqueued_job(described_class).with(product.id)
    end
  end
end
