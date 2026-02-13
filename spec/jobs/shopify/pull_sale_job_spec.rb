# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::PullSaleJob, :aggregate_failures do
  let(:job) { described_class.new }
  let(:sale_id) { "gid://shopify/Order/123" }

  describe "#perform" do
    let(:order_response) do
      {
        "id" => sale_id,
        "name" => "#1001",
        "displayFinancialStatus" => "PAID",
        "displayFulfillmentStatus" => "UNFULFILLED",
        "email" => "customer@example.com",
        "customer" => {
          "id" => "gid://shopify/Customer/456",
          "firstName" => "Jane",
          "lastName" => "Smith"
        }
      }
    end

    before do
      # rubocop:disable RSpec/VerifiedDoubles
      mock_client = spy("Shopify::Api::Client")
      # rubocop:enable RSpec/VerifiedDoubles
      allow(mock_client).to receive(:fetch_order).and_return(order_response)
      allow(Shopify::Api::Client).to receive(:new).and_return(mock_client)
    end

    it "creates a sale from Shopify order data" do
      expect { job.perform(sale_id) }
        .to change(Sale, :count).by(1)
        .and change(Customer, :count).by(1)
    end

    it "raises ArgumentError when sale_id is nil" do
      expect { job.perform(nil) }.to raise_error(ArgumentError, "Shopify order ID is required")
    end

    it "raises ArgumentError when sale_id is empty" do
      expect { job.perform("") }.to raise_error(ArgumentError, "Shopify order ID is required")
    end

    context "when sale already exists" do
      before { create(:sale, shopify_id: sale_id) }

      it "updates existing sale instead of creating duplicate" do
        expect { job.perform(sale_id) }.not_to change(Sale, :count)
      end
    end
  end
end
