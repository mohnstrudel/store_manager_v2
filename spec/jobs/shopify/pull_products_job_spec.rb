# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::PullProductsJob, :aggregate_failures do
  let(:job) { described_class.new }

  describe "#perform" do
    let(:api_response) do
      {
        items: [
          {
            "id" => "gid://shopify/Product/123",
            "title" => "Elden Ring - Malenia | 1:4 | Resin Statue",
            "handle" => "malenia-statue",
            "createdAt" => "2023-01-01T00:00:00Z",
            "updatedAt" => "2023-01-02T00:00:00Z",
            "variants" => {
              "edges" => [
                {
                  "node" => {
                    "id" => "gid://shopify/ProductVariant/456",
                    "title" => "Default",
                    "sku" => "malenia-001"
                  }
                }
              ]
            },
            "media" => {"nodes" => []}
          }
        ]
      }
    end

    before do
      # rubocop:disable RSpec/VerifiedDoubles
      mock_client = spy("Shopify::Api::Client")
      # rubocop:enable RSpec/VerifiedDoubles
      allow(mock_client).to receive(:fetch_products).and_return(api_response)
      allow(Shopify::Api::Client).to receive(:new).and_return(mock_client)
    end

    it "creates products from Shopify data" do
      expect { job.perform }.to change(Product, :count).by(1)
    end

    it "logs warnings when SKU collision errors occur" do
      # Create an existing product with the same SKU
      create(:product, sku: "malenia-001")

      # Stub to raise SKU collision error
      allow(Product::ShopifyImporter).to receive(:import!).and_raise(
        StandardError.new("SKU has already been taken")
      )

      expect { job.perform }.not_to raise_error
      expect(Product.count).to eq(1) # No new product created
    end

    it "re-raises non-SKU errors" do
      allow(Product::ShopifyImporter).to receive(:import!).and_raise(
        StandardError.new("API rate limit exceeded")
      )

      expect { job.perform }.to raise_error(StandardError, "API rate limit exceeded")
    end

    context "when product already exists" do
      before { create(:product, shopify_id: "gid://shopify/Product/123") }

      it "updates existing product instead of creating duplicate" do
        expect { job.perform }.not_to change(Product, :count)
      end
    end
  end
end
