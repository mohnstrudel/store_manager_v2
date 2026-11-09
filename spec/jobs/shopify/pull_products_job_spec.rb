# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::PullProductsJob, :aggregate_failures do
  include ActiveJob::TestHelper

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

      it "still stores the start time of the pull" do
        started_at = Time.utc(2026, 11, 10, 12)

        travel_to(started_at) { described_class.perform_now }

        expect(Config.shopify_products_sync_at).to eq(started_at)
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

  describe "sync time" do
    let(:client) { instance_double(Shopify::Api::Client) }
    let(:started_at) { Time.utc(2026, 11, 10, 12) }

    before do
      allow(Shopify::Api::Client).to receive(:new).and_return(client)
      allow(client).to receive(:fetch_products).and_return(items: [], has_next_page: false, end_cursor: nil)
    end

    it "stores the start of a full pull as the products sync time on its last page and leaves the sales sync time alone" do
      travel_to(started_at) { described_class.perform_now }

      expect(Config.shopify_products_sync_at).to eq(started_at)
      expect(Config.shopify_sales_sync_at).to be_nil
    end

    it "fetches the products updated since 15 minutes before the stored products sync time on a changes pull" do
      Config.update_shopify_products_sync_time(Time.utc(2026, 11, 10, 10))
      Config.update_shopify_sales_sync_time(Time.utc(2026, 11, 10, 11))

      travel_to(started_at) { described_class.perform_now(changes_only: true) }

      expect(client).to have_received(:fetch_products)
        .with(cursor: nil, batch_size: 250, updated_since: Time.utc(2026, 11, 10, 9, 45))
      expect(Config.shopify_products_sync_at).to eq(started_at)
    end

    it "pulls three pages of a changes pull with one filter and stores the start time only after the third" do
      Config.update_shopify_products_sync_time(Time.utc(2026, 11, 10, 10))
      allow(client).to receive(:fetch_products).and_return(
        {items: [], has_next_page: true, end_cursor: "cursor-1"},
        {items: [], has_next_page: true, end_cursor: "cursor-2"},
        {items: [], has_next_page: false, end_cursor: nil}
      )

      travel_to(started_at) { described_class.perform_now(changes_only: true) }
      travel_to(started_at + 1.minute) { ActiveJob::Base.execute(enqueued_jobs.last) }
      expect(Config.shopify_products_sync_at).to eq(Time.utc(2026, 11, 10, 10))
      travel_to(started_at + 3.minutes) { ActiveJob::Base.execute(enqueued_jobs.last) }

      filter = Time.utc(2026, 11, 10, 9, 45)
      expect(client).to have_received(:fetch_products).with(cursor: nil, batch_size: 250, updated_since: filter)
      expect(client).to have_received(:fetch_products).with(cursor: "cursor-1", batch_size: 250, updated_since: filter)
      expect(client).to have_received(:fetch_products).with(cursor: "cursor-2", batch_size: 250, updated_since: filter)
      expect(Config.shopify_products_sync_at).to eq(started_at)
    end

    it "fetches every product when a changes pull has no stored products sync time" do
      described_class.perform_now(changes_only: true)

      expect(client).to have_received(:fetch_products).with(cursor: nil, batch_size: 250, updated_since: nil)
    end

    it "stores nothing before the last page" do
      allow(client).to receive(:fetch_products).and_return(items: [], has_next_page: true, end_cursor: "cursor-1")

      described_class.perform_now

      expect(Config.shopify_products_sync_at).to be_nil
    end

    it "keeps the stored USD prices of products a changes pull does not return" do
      unchanged = create(
        :variant, :synced,
        selling_price: BigDecimal("521.01"), selling_price_source_amount: BigDecimal("450.00"),
        selling_price_source_currency: "EUR", selling_price_exchange_rate: BigDecimal("1.1578"),
        selling_price_exchange_rate_date: Date.new(2026, 9, 2)
      )
      Config.update_shopify_products_sync_time(Time.utc(2026, 11, 10, 10))

      described_class.perform_now(changes_only: true)

      expect(unchanged.reload).to have_attributes(
        selling_price: BigDecimal("521.01"),
        selling_price_exchange_rate: BigDecimal("1.1578"),
        selling_price_exchange_rate_date: Date.new(2026, 9, 2)
      )
    end
  end
end
