# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::PushMediaJob do
  include ActiveJob::TestHelper

  describe ".perform_later" do
    let(:shopify_product_id) { "gid://shopify/Product/123" }
    let(:product) { create(:product_with_brands) }

    it "enqueues the job with correct arguments" do
      expect {
        described_class.perform_later(shopify_product_id, product.id)
      }.to have_enqueued_job(described_class).with(shopify_product_id, product.id).exactly(:once)
    end
  end

  describe "#perform" do
    it "delegates to Product::Shopify::Media::Push" do
      allow(Product::Shopify::Media::Push).to receive(:call)

      described_class.new.perform(42, "gid://shopify/Product/123")

      expect(Product::Shopify::Media::Push).to have_received(:call).with(
        product_id: 42,
        product_store_id: "gid://shopify/Product/123"
      )
    end
  end
end
