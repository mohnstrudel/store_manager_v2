# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::PullSalesJob, :aggregate_failures do
  include ActiveJob::TestHelper

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

      allow(Sale::Shopify::Importer).to receive(:import).and_raise(
        StandardError.new("SKU has already been taken")
      )

      expect { job.perform }.to raise_error(StandardError, "SKU has already been taken")
    end

    it "re-raises non-SKU errors" do
      allow(Sale::Shopify::Importer).to receive(:import).and_raise(
        StandardError.new("API rate limit exceeded")
      )

      expect { job.perform }.to raise_error(StandardError, "API rate limit exceeded")
    end

    context "when an order fails with a known importer error" do
      let(:failing_order) { api_response[:items].first.merge("id" => "gid://shopify/Order/999", "name" => "#999") }

      before do
        api_response[:items] << failing_order
        api_response.merge!(has_next_page: true, end_cursor: "cursor-1")
        allow(Sale::Shopify::Importer).to receive(:import).and_call_original
        allow(Sale::Shopify::Importer).to receive(:import)
          .with(hash_including(store_info: hash_including(store_id: "gid://shopify/Order/999")))
          .and_raise(Sale::Shopify::Importer::Error, "Failed to process SaleItem: Variant must be selected")
        allow(Sentry).to receive(:capture_exception)
      end

      it "imports the rest of the page, schedules the next page, then reports the failure without retrying" do
        expect { described_class.perform_now }.to change(Sale, :count).by(1)
          .and have_enqueued_job(described_class).with(hash_including(cursor: "cursor-1"))

        expect(Sentry).to have_received(:capture_exception).with(
          an_instance_of(Shopify::Pull::Failed)
            .and(having_attributes(
              failures: [having_attributes(store_id: "gid://shopify/Order/999", message: "Failed to process SaleItem: Variant must be selected")],
              message: /1 Shopify item\(s\) failed to import: gid:\/\/shopify\/Order\/999: Failed to process SaleItem/
            ))
        )
        expect(enqueued_jobs.count { |enqueued| enqueued["job_class"] == described_class.name }).to eq(1)
      end

      it "records the failed order with the Sentry event id and failure time" do
        sale = create(:sale, shopify_store_id: "gid://shopify/Order/999")
        allow(Sentry).to receive(:capture_exception).and_return(instance_double(Sentry::ErrorEvent, event_id: "event-1"))

        freeze_time do
          described_class.perform_now

          expect(Sale::ImportFailure.find_by!(store_name: "shopify", store_order_id: "gid://shopify/Order/999")).to have_attributes(
            sale:,
            message: "Failed to process SaleItem: Variant must be selected",
            sentry_event_id: "event-1",
            last_failed_at: Time.current
          )
        end
      end

      it "reports a recording failure and stays discarded with one next-page job" do
        recording_error = ActiveRecord::StatementInvalid.new("cannot write")
        allow(Sale::ImportFailure).to receive(:record).and_raise(recording_error)

        expect { described_class.perform_now }.not_to raise_error

        expect(Sentry).to have_received(:capture_exception).with(
          recording_error,
          extra: {store_name: "shopify", store_order_id: "gid://shopify/Order/999"}
        )
        expect(enqueued_jobs.count { |enqueued| enqueued["job_class"] == described_class.name }).to eq(1)
      end
    end

    context "when sale already exists" do
      before { create(:sale, :synced, shopify_id: "gid://shopify/Order/123") }

      it "updates existing sale instead of creating duplicate" do
        expect { job.perform }.not_to change(Sale, :count)
      end
    end

    context "when Shopify throttles the fetch of a product an order references" do
      let(:order_with_uncached_product) do
        api_response[:items].first.merge(
          "lineItems" => {
            "nodes" => [{
              "id" => "gid://shopify/LineItem/1",
              "title" => "Star Wars - Princess Leia | 1:4 Resin Statue",
              "quantity" => 1,
              "variant" => {"id" => "gid://shopify/ProductVariant/66", "product" => {"id" => "gid://shopify/Product/55"}},
              "product" => {"id" => "gid://shopify/Product/55"}
            }]
          }
        )
      end
      let(:client) { instance_double(Shopify::Api::Client, fetch_orders: {items: [order_with_uncached_product], has_next_page: true, end_cursor: "cursor-1"}) }

      before do
        allow(client).to receive(:fetch_product).and_raise(Shopify::Api::Client::Throttled)
        allow(Shopify::Api::Client).to receive(:new).and_return(client)
      end

      it "retries the same page instead of counting the order as a failure or moving to the next page" do
        expect { described_class.perform_now(cursor: "cursor-0") }
          .to have_enqueued_job(described_class).with(cursor: "cursor-0")

        expect(enqueued_jobs.count { |enqueued| enqueued["job_class"] == described_class.name }).to eq(1)
        expect(Sale::ImportFailure.count).to eq(0)
        expect(Sale.count).to eq(0)
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
    end

    it "enqueues one Seal sync after the last page of a changes pull" do
      Config.update_shopify_sales_sync_time(Time.utc(2026, 11, 10, 10))

      job.perform(changes_only: true)

      expect(Seal::SyncPaymentPlansJob).to have_received(:perform_later).once
    end

    context "when import fails" do
      let(:api_response) { {items: [{"id" => "gid://shopify/Order/999"}], has_next_page: false, end_cursor: nil} }

      before do
        allow(Sale::Shopify::Parser).to receive(:parse).and_return({})
        allow(Sale::Shopify::Importer).to receive(:import).and_raise(StandardError, "boom")
      end

      it "does not enqueue Seal" do
        expect { job.perform }.to raise_error(StandardError, "boom")
        expect(Seal::SyncPaymentPlansJob).not_to have_received(:perform_later)
      end
    end
  end

  describe "sync time" do
    let(:client) { instance_double(Shopify::Api::Client) }
    let(:started_at) { Time.utc(2026, 11, 10, 12) }

    before do
      allow(Shopify::Api::Client).to receive(:new).and_return(client)
      allow(client).to receive(:fetch_orders).and_return(items: [], has_next_page: false, end_cursor: nil)
    end

    it "stores the start of a full pull as the sales sync time on its last page and leaves the products sync time alone" do
      travel_to(started_at) { described_class.perform_now }

      expect(Config.shopify_sales_sync_at).to eq(started_at)
      expect(Config.shopify_products_sync_at).to be_nil
    end

    it "fetches the orders updated since 15 minutes before the stored sales sync time on a changes pull" do
      Config.update_shopify_sales_sync_time(Time.utc(2026, 11, 10, 10))
      Config.update_shopify_products_sync_time(Time.utc(2026, 11, 10, 11))

      travel_to(started_at) { described_class.perform_now(changes_only: true) }

      expect(client).to have_received(:fetch_orders)
        .with(cursor: nil, batch_size: 250, updated_since: Time.utc(2026, 11, 10, 9, 45))
      expect(Config.shopify_sales_sync_at).to eq(started_at)
    end

    it "fetches every order when a changes pull has no stored sales sync time" do
      described_class.perform_now(changes_only: true)

      expect(client).to have_received(:fetch_orders).with(cursor: nil, batch_size: 250, updated_since: nil)
    end

    it "stores the start time although an order on the last page failed to import" do
      allow(client).to receive(:fetch_orders)
        .and_return(items: [{"id" => "gid://shopify/Order/999"}], has_next_page: false, end_cursor: nil)
      allow(Sale::Shopify::Parser).to receive(:parse).and_return({})
      allow(Sale::Shopify::Importer).to receive(:import).and_raise(Sale::Shopify::Importer::Error, "Variant must be selected")
      allow(Sentry).to receive(:capture_exception)

      travel_to(started_at) { described_class.perform_now }

      expect(Config.shopify_sales_sync_at).to eq(started_at)
      expect(Sale::ImportFailure.shopify.unresolved.pluck(:store_order_id)).to eq(["gid://shopify/Order/999"])
    end

    it "stores nothing before the last page" do
      allow(client).to receive(:fetch_orders).and_return(items: [], has_next_page: true, end_cursor: "cursor-1")

      described_class.perform_now

      expect(Config.shopify_sales_sync_at).to be_nil
    end
  end

  describe "retrying unresolved import failures" do
    let(:client) { instance_double(Shopify::Api::Client) }
    let(:last_page) { {items: [], has_next_page: false, end_cursor: nil} }

    def record_failure(store_name, store_order_id)
      Sale::ImportFailure.record(
        store_name:, store_order_id:, message: "boom", sentry_event_id: nil, failed_at: Time.zone.local(2026, 11, 10, 8)
      )
    end

    def enqueued_arguments(job_class)
      enqueued_jobs.select { |enqueued| enqueued["job_class"] == job_class.name }.pluck("arguments")
    end

    before do
      allow(Shopify::Api::Client).to receive(:new).and_return(client)
      allow(client).to receive(:fetch_orders).and_return(last_page)
      Config.update_shopify_sales_sync_time(Time.utc(2026, 11, 10, 10))
      record_failure("shopify", "gid://shopify/Order/1")
      record_failure("shopify", "gid://shopify/Order/2")
      record_failure("shopify", "gid://shopify/Order/3")
      Sale::ImportFailure.resolve(store_name: "shopify", store_order_id: "gid://shopify/Order/3")
      record_failure("woo", "77")
    end

    it "enqueues one single-order pull per unresolved Shopify failure on the last page of a changes pull" do
      described_class.perform_now(changes_only: true)

      expect(enqueued_arguments(Shopify::PullSaleJob))
        .to contain_exactly(["gid://shopify/Order/1"], ["gid://shopify/Order/2"])
    end

    it "enqueues no Woo pull for the Woo failure" do
      described_class.perform_now(changes_only: true)

      expect(enqueued_arguments(Woo::PullSalesJob)).to be_empty
    end

    it "enqueues no retries before the last page" do
      allow(client).to receive(:fetch_orders).and_return(last_page.merge(has_next_page: true, end_cursor: "cursor-1"))

      described_class.perform_now(changes_only: true)

      expect(enqueued_arguments(Shopify::PullSaleJob)).to be_empty
    end

    it "enqueues no retries for a full pull, which reads every order anyway" do
      described_class.perform_now

      expect(enqueued_arguments(Shopify::PullSaleJob)).to be_empty
    end

    it "enqueues no retries when a changes pull has no stored sync time and so reads every order" do
      Config.update_shopify_sales_sync_time(nil)

      described_class.perform_now(changes_only: true)

      expect(enqueued_arguments(Shopify::PullSaleJob)).to be_empty
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
