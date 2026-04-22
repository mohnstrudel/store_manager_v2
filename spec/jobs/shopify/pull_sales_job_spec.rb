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
            "totalPriceSet" => {"shopMoney" => {"amount" => "100.00"}},
            "totalDiscountsSet" => {"shopMoney" => {"amount" => "0.00"}},
            "totalShippingPriceSet" => {"shopMoney" => {"amount" => "0.00"}},
            "customer" => {
              "id" => "gid://shopify/Customer/456",
              "firstName" => "John",
              "lastName" => "Doe",
              "defaultEmailAddress" => {"emailAddress" => "customer@example.com"},
              "defaultPhoneNumber" => {"phoneNumber" => "555-1234"}
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
      allow(Config).to receive(:update_shopify_sales_sync_time)
    end

    it "creates sales from Shopify order data" do
      expect { job.perform }
        .to change(Sale, :count).by(1)
        .and change(Customer, :count).by(1)
    end

    it "re-raises SKU collision errors" do
      # Create a product that will cause SKU collision
      product = create(:product)
      create(:edition, product:, sku: "test-001")
      create(:sale, shopify_id: "gid://shopify/Order/123")

      # Stub to raise SKU collision error
      allow(Sale::Shopify::Importer).to receive(:import!).and_raise(
        StandardError.new("SKU has already been taken")
      )

      expect { job.perform }.to raise_error(StandardError, "SKU has already been taken")
    end

    it "re-raises non-SKU errors" do
      allow(Sale::Shopify::Importer).to receive(:import!).and_raise(
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
