# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::PullSalesJob, :aggregate_failures do
  let(:job) { described_class.new }

  before do
    create(:exchange_rate, date: Date.new(2000, 1, 1), currency: "USD", rate: BigDecimal("1.0000"))
  end

  describe "#perform" do
    let(:api_response) do
      {
        items: [
          {
            "id" => "gid://shopify/Order/123",
            "name" => "#1001",
            "createdAt" => "2023-01-01T00:00:00Z",
            "updatedAt" => "2023-01-02T00:00:00Z",
            "currencyCode" => "EUR",
            "presentmentCurrencyCode" => "EUR",
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
      product = create(:product)
      create(:variant, product:, sku: "test-001")
      create(:sale, shopify_id: "gid://shopify/Order/123")

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

    it "logs and skips known importer validation failures instead of aborting the page" do
      allow(Sale::Shopify::Importer).to receive(:import!).and_raise(
        Sale::Shopify::Importer::Error.new("Failed to process SaleItem: Variant must be selected")
      )
      allow(Rails.logger).to receive(:error)

      expect { job.perform }.not_to raise_error
      expect(Rails.logger).to have_received(:error).with(/Skipping Shopify order due to import failure/)
      expect(Sale.count).to eq(0)
    end

    context "when sale already exists" do
      before { create(:sale, shopify_id: "gid://shopify/Order/123") }

      it "updates existing sale instead of creating duplicate" do
        expect { job.perform }.not_to change(Sale, :count)
      end
    end
  end

  describe "Seal sync handoff" do
    let(:api_response) { {items: [], has_next_page: false, end_cursor: nil} }

    before do
      # rubocop:disable RSpec/VerifiedDoubles
      mock_client = spy("Shopify::Api::Client")
      # rubocop:enable RSpec/VerifiedDoubles
      allow(mock_client).to receive(:fetch_orders).and_return(api_response)
      allow(Shopify::Api::Client).to receive(:new).and_return(mock_client)
      allow(Config).to receive(:update_shopify_sales_sync_time)
      allow(Seal::SyncPaymentPlansJob).to receive(:perform_later)
    end

    it "enqueues one Seal sync after the terminal full-history page imports successfully" do
      job.perform

      expect(Seal::SyncPaymentPlansJob).to have_received(:perform_later)
    end

    context "when Shopify reports another page" do
      let(:api_response) { {items: [], has_next_page: true, end_cursor: "cursor-1"} }

      it "does not enqueue Seal for an intermediate page" do
        job.perform

        expect(Seal::SyncPaymentPlansJob).not_to have_received(:perform_later)
      end

      it "enqueues Seal for a limited pull even though another page remains" do
        job.perform(limit: 3)

        expect(Seal::SyncPaymentPlansJob).to have_received(:perform_later)
      end
    end

    context "when import fails" do
      let(:api_response) { {items: [{"id" => "gid://shopify/Order/999"}], has_next_page: false, end_cursor: nil} }

      before do
        allow(Sale::Shopify::Parser).to receive(:parse).and_return({})
        allow(Sale::Shopify::Importer).to receive(:import!).and_raise(StandardError, "boom")
      end

      it "does not enqueue Seal" do
        expect { job.perform }.to raise_error(StandardError, "boom")
        expect(Seal::SyncPaymentPlansJob).not_to have_received(:perform_later)
      end
    end
  end

  describe "limited pull" do
    let(:api_response) do
      {
        items: [],
        has_next_page: false,
        end_cursor: nil
      }
    end

    it "requests only the given batch size through the normal query, parser, and importer" do
      # rubocop:disable RSpec/VerifiedDoubles
      mock_client = spy("Shopify::Api::Client")
      # rubocop:enable RSpec/VerifiedDoubles
      allow(mock_client).to receive(:fetch_orders).and_return(api_response)
      allow(Shopify::Api::Client).to receive(:new).and_return(mock_client)

      job.perform(limit: 3)

      expect(mock_client).to have_received(:fetch_orders).with(cursor: nil, batch_size: 3)
    end
  end

  describe "USD conversion parity across synchronization entry points" do
    let(:eur_order) do
      {
        "id" => "gid://shopify/Order/parity-bulk",
        "name" => "#2001",
        "createdAt" => "2026-08-21T12:00:00Z",
        "updatedAt" => "2026-08-21T12:05:00Z",
        "currencyCode" => "EUR",
        "presentmentCurrencyCode" => "CHF",
        "displayFinancialStatus" => "PAID",
        "displayFulfillmentStatus" => "UNFULFILLED",
        "email" => "parity@example.com",
        "totalPriceSet" => {"shopMoney" => {"amount" => "100.00"}},
        "totalDiscountsSet" => {"shopMoney" => {"amount" => "8.00"}},
        "totalShippingPriceSet" => {"shopMoney" => {"amount" => "4.00"}},
        "customer" => {
          "id" => "gid://shopify/Customer/parity",
          "firstName" => "Parity",
          "lastName" => "Tester",
          "defaultEmailAddress" => {"emailAddress" => "parity@example.com"}
        },
        "lineItems" => {"nodes" => []}
      }
    end

    before do
      create(:exchange_rate, date: Date.new(2026, 8, 21), currency: "USD", rate: BigDecimal("1.1250"))
    end

    it "produces identical USD values and currency data through the bulk and single-order jobs" do
      # rubocop:disable RSpec/VerifiedDoubles
      bulk_client = spy("Shopify::Api::Client")
      # rubocop:enable RSpec/VerifiedDoubles
      allow(bulk_client).to receive(:fetch_orders).and_return(items: [eur_order], has_next_page: false, end_cursor: nil)
      allow(Shopify::Api::Client).to receive(:new).and_return(bulk_client)
      job.perform

      single_order = eur_order.merge("id" => "gid://shopify/Order/parity-single")
      # rubocop:disable RSpec/VerifiedDoubles
      single_client = spy("Shopify::Api::Client")
      # rubocop:enable RSpec/VerifiedDoubles
      allow(single_client).to receive(:fetch_order).and_return(single_order)
      allow(Shopify::Api::Client).to receive(:new).and_return(single_client)
      Shopify::PullSaleJob.new.perform(single_order["id"])

      bulk_sale = Sale.find_by_shopify_id(eur_order["id"])
      single_sale = Sale.find_by_shopify_id(single_order["id"])

      expect(bulk_sale).to have_attributes(
        total: BigDecimal("112.50"),
        discount_total: BigDecimal("9.00"),
        shipping_total: BigDecimal("4.50"),
        shop_currency: "EUR",
        presentment_currency: "CHF",
        usd_conversion_rate: BigDecimal("1.1250"),
        exchange_rate_date: Date.new(2026, 8, 21)
      )
      expect(single_sale).to have_attributes(
        total: bulk_sale.total,
        discount_total: bulk_sale.discount_total,
        shipping_total: bulk_sale.shipping_total,
        shop_currency: bulk_sale.shop_currency,
        presentment_currency: bulk_sale.presentment_currency,
        usd_conversion_rate: bulk_sale.usd_conversion_rate,
        exchange_rate_date: bulk_sale.exchange_rate_date
      )
    end

    it "keeps one stable sale when the bulk job then the single-order job import the same order" do
      # rubocop:disable RSpec/VerifiedDoubles
      bulk_client = spy("Shopify::Api::Client")
      # rubocop:enable RSpec/VerifiedDoubles
      allow(bulk_client).to receive(:fetch_orders).and_return(items: [eur_order], has_next_page: false, end_cursor: nil)
      allow(Shopify::Api::Client).to receive(:new).and_return(bulk_client)
      job.perform
      bulk_sale = Sale.find_by_shopify_id(eur_order["id"])

      # rubocop:disable RSpec/VerifiedDoubles
      single_client = spy("Shopify::Api::Client")
      # rubocop:enable RSpec/VerifiedDoubles
      allow(single_client).to receive(:fetch_order).and_return(eur_order)
      allow(Shopify::Api::Client).to receive(:new).and_return(single_client)

      expect {
        Shopify::PullSaleJob.new.perform(eur_order["id"])
      }.not_to change(Sale, :count)

      expect(Sale.find_by_shopify_id(eur_order["id"])).to eq(bulk_sale)
    end
  end
end
