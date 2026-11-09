# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::PullProductsJob, :aggregate_failures do
  let(:job) { described_class.new }

  describe "#perform" do
    let(:parsed_product) do
      {
        store_id: "gid://shopify/Product/123",
        title: "Malenia",
        franchise: "Elden Ring",
        shape: "Statue",
        sku: "malenia-001",
        store_link: "malenia-statue",
        variants: [],
        media: []
      }
    end

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
      allow(Product::Shopify::Parser).to receive(:parse).and_return(parsed_product)
    end

    it "creates products from Shopify data" do
      allow(Product::Shopify::Importer).to receive(:import).and_call_original

      expect { job.perform }.to change(Product, :count).by(1)
    end

    context "when a product fails to import" do
      let(:failed_page) do
        Shopify::Pull::Page.new(
          imported_count: 0,
          next_cursor: nil,
          failures: [Shopify::Pull::Failure.new(store_id: "gid://shopify/Product/123", message: "boom", failed_at: Time.current)]
        )
      end

      before do
        allow(Product::Shopify::Pull).to receive(:page).and_return(failed_page)
        allow(Sentry).to receive(:capture_exception)
      end

      it "reports to Sentry and writes no import failure" do
        expect { described_class.perform_now }.not_to change(Sale::ImportFailure, :count)

        expect(Sentry).to have_received(:capture_exception).with(an_instance_of(Shopify::Pull::Failed))
      end
    end

    context "when product already exists" do
      before { create(:product, :synced, shopify_id: "gid://shopify/Product/123") }

      it "updates existing product instead of creating duplicate" do
        allow(Product::Shopify::Importer).to receive(:import).and_call_original

        expect { job.perform }.not_to change(Product, :count)
      end
    end
  end
end
