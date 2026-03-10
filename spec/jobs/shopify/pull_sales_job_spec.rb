# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::PullSalesJob, :aggregate_failures do
  let(:job) { described_class.new }

  describe "#perform" do
    let(:api_response) do
      {
        items: [
          {
            "id" => "gid://shopify/Order/123",
            "name" => "#1001",
            "createdAt" => "2023-01-01T00:00:00Z",
            "updatedAt" => "2023-01-02T00:00:00Z",
            "displayFinancialStatus" => "PAID",
            "displayFulfillmentStatus" => "UNFULFILLED",
            "email" => "customer@example.com",
            "customer" => {
              "id" => "gid://shopify/Customer/456",
              "firstName" => "John",
              "lastName" => "Doe",
              "email" => "customer@example.com",
              "phone" => "555-1234"
            },
            "lineItems" => {nodes: []}
          }
        ]
      }
    end

    before do
      # rubocop:disable RSpec/VerifiedDoubles
      mock_client = spy("Shopify::Api::Client")
      # rubocop:enable RSpec/VerifiedDoubles
      allow(mock_client).to receive(:fetch_orders).and_return(api_response)
      allow(Shopify::Api::Client).to receive(:new).and_return(mock_client)
    end

    it "creates sales from Shopify order data" do
      expect { job.perform }
        .to change(Sale, :count).by(1)
        .and change(Customer, :count).by(1)
    end

    it "logs warnings when SKU collision errors occur" do
      # Create a product that will cause SKU collision
      create(:product, sku: "test-001")
      create(:sale, shopify_id: "gid://shopify/Order/123")

      # Stub to raise SKU collision error
      allow(Sale::ShopifyImporter).to receive(:import!).and_raise(
        StandardError.new("SKU has already been taken")
      )

      expect { job.perform }.not_to raise_error
      expect(Sale.count).to eq(1) # No new sale created
    end

    it "re-raises non-SKU errors" do
      allow(Sale::ShopifyImporter).to receive(:import!).and_raise(
        StandardError.new("API rate limit exceeded")
      )

      expect { job.perform }.to raise_error(StandardError, "API rate limit exceeded")
    end

    context "when sale already exists" do
      before { create(:sale, shopify_id: "gid://shopify/Order/123") }

      it "updates existing sale instead of creating duplicate" do
        expect { job.perform }.not_to change(Sale, :count)
      end
    end
  end
end
