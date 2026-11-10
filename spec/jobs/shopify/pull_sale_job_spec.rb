# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::PullSaleJob, :aggregate_failures do
  include ActiveJob::TestHelper

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
        "totalPriceSet" => {"shopMoney" => {"amount" => "100.00", "currencyCode" => "USD"}},
        "totalDiscountsSet" => {"shopMoney" => {"amount" => "0.00", "currencyCode" => "USD"}},
        "totalShippingPriceSet" => {"shopMoney" => {"amount" => "0.00", "currencyCode" => "USD"}},
        "customer" => {
          "id" => "gid://shopify/Customer/456",
          "firstName" => "Jane",
          "lastName" => "Smith",
          "defaultEmailAddress" => {"emailAddress" => "customer@example.com"}
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

    it "never starts a full Seal sync" do
      allow(Seal::SyncPaymentPlansJob).to receive(:perform_later)

      job.perform(sale_id)

      expect(Seal::SyncPaymentPlansJob).not_to have_received(:perform_later)
    end

    it "raises ArgumentError when sale_id is nil" do
      expect { job.perform(nil) }.to raise_error(ArgumentError, "Sale store_id is required")
    end

    it "raises ArgumentError when sale_id is empty" do
      expect { job.perform("") }.to raise_error(ArgumentError, "Sale store_id is required")
    end

    context "when Shopify throttles the order fetch" do
      before do
        client = instance_double(Shopify::Api::Client)
        allow(client).to receive(:fetch_order).and_raise(Shopify::Api::Client::Throttled)
        allow(Shopify::Api::Client).to receive(:new).and_return(client)
      end

      it "re-enqueues the job with the same order id" do
        expect { described_class.perform_now(sale_id) }.to have_enqueued_job(described_class).with(sale_id)
      end

      it "records no import failure" do
        expect { described_class.perform_now(sale_id) }.not_to change(Sale::ImportFailure, :count)
      end
    end

    context "when Shopify has no such order" do
      let(:user) { create(:user) }
      let(:client) { instance_double(Shopify::Api::Client, fetch_order: nil) }

      before do
        allow(Shopify::Api::Client).to receive(:new).and_return(client)
        allow(Sentry).to receive(:capture_exception)
      end

      it "discards the job without retrying or reporting" do
        expect { described_class.perform_now(sale_id) }.not_to raise_error

        expect(enqueued_jobs).to be_empty
        expect(Sentry).not_to have_received(:capture_exception)
      end

      it "resolves the order's unresolved import failure so nothing retries it" do
        Sale::ImportFailure.record(store_name: "shopify", store_order_id: sale_id, message: "boom", sentry_event_id: nil, failed_at: 1.hour.ago)

        described_class.perform_now(sale_id)

        expect(Sale::ImportFailure.shopify.unresolved).to be_empty
        expect(Sale::ImportFailure.find_by!(store_name: "shopify", store_order_id: sale_id).resolved_at).to be_present
      end

      it "records no import failure for an order that never failed" do
        expect { described_class.perform_now(sale_id) }.not_to change(Sale::ImportFailure, :count)
      end

      it "tells the requester the order was not found" do
        expect { described_class.perform_now(sale_id, requested_by: user) }
          .to have_broadcasted_to(user).from_channel(NotificationsChannel)
          .with(kind: "alert", message: "This order was not found in Shopify.")
      end
    end

    context "when Shopify rejects the order query" do
      let(:user) { create(:user) }
      let(:client) { instance_double(Shopify::Api::Client) }

      before do
        allow(client).to receive(:fetch_order).and_raise(Shopify::Api::Client::ApiError, "Failed to fetch order: Access denied")
        allow(Shopify::Api::Client).to receive(:new).and_return(client)
        allow(Sentry).to receive(:capture_exception).and_return(instance_double(Sentry::ErrorEvent, event_id: "event-1"))
      end

      it "records the order's import failure and discards the job instead of retrying" do
        sale = create(:sale, shopify_store_id: sale_id)

        expect { described_class.perform_now(sale_id) }.not_to raise_error

        expect(enqueued_jobs).to be_empty
        expect(Sale::ImportFailure.find_by!(store_name: "shopify", store_order_id: sale_id)).to have_attributes(
          sale:, message: "Failed to fetch order: Access denied", sentry_event_id: "event-1", failure_count: 1
        )
      end

      it "tells the requester the order could not be pulled" do
        expect { described_class.perform_now(sale_id, requested_by: user) }
          .to have_broadcasted_to(user).from_channel(NotificationsChannel)
          .with(kind: "alert", message: "This order could not be pulled from Shopify.", link: {label: "Open broken sales", href: "/broken_sales"})
      end
    end

    context "when the order references a product that is not cached locally" do
      let(:product_store_id) { "gid://shopify/Product/55" }
      let(:variant_store_id) { "gid://shopify/ProductVariant/66" }
      let(:product_response) do
        {
          "id" => product_store_id,
          "title" => "Star Wars - Princess Leia | 1:4 Resin Statue | by von xionart",
          "handle" => "star-wars-princess-leia",
          "variants" => {
            "edges" => [
              {"node" => {"id" => variant_store_id, "title" => "Big Chest", "sku" => "leia-big", "selectedOptions" => [{"name" => "Version", "value" => "Big Chest"}]}},
              {"node" => {"id" => "gid://shopify/ProductVariant/67", "title" => "Normal Chest", "sku" => "leia-normal", "selectedOptions" => [{"name" => "Version", "value" => "Normal Chest"}]}}
            ]
          },
          "media" => {"nodes" => []}
        }
      end
      let(:client) { instance_double(Shopify::Api::Client, fetch_order: order_with_line, fetch_product: product_response) }
      let(:order_with_line) do
        order_response.merge(
          "lineItems" => {
            "nodes" => [{
              "id" => "gid://shopify/LineItem/1",
              "title" => "Star Wars - Princess Leia | 1:4 Resin Statue",
              "quantity" => 1,
              "variantTitle" => "Big Chest",
              "variant" => {"id" => variant_store_id, "product" => {"id" => product_store_id}},
              "product" => {"id" => product_store_id}
            }]
          }
        )
      end

      before do
        allow(Shopify::Api::Client).to receive(:new).and_return(client)
        allow(Shopify::ImportMediaJob).to receive(:perform_later)
      end

      it "imports the product and its variants first, so the sale item lands on its own variant" do
        job.perform(sale_id)

        sale_item = Sale::Shopify::OrderId.find_sale(sale_id).sale_items.sole
        expect(sale_item.product.shopify_info.store_id).to eq(product_store_id)
        expect(sale_item.variant.shopify_info.store_id).to eq(variant_store_id)
      end

      it "queues no product pull" do
        allow(Shopify::PullProductJob).to receive(:perform_later)

        job.perform(sale_id)

        expect(Shopify::PullProductJob).not_to have_received(:perform_later)
      end

      context "when Shopify throttles the product fetch" do
        before { allow(client).to receive(:fetch_product).and_raise(Shopify::Api::Client::Throttled) }

        it "re-enqueues the job with the same order id" do
          expect { described_class.perform_now(sale_id) }.to have_enqueued_job(described_class).with(sale_id)
        end

        it "records no import failure and saves no sale" do
          expect { described_class.perform_now(sale_id) }.not_to change { [Sale::ImportFailure.count, Sale.count] }
        end
      end

      context "when the product fetch fails" do
        before do
          allow(client).to receive(:fetch_product).and_raise(Shopify::Api::Client::ApiError, "Failed to fetch product: Access denied")
          allow(Sentry).to receive(:capture_exception)
        end

        it "records the order's import failure and discards the job" do
          expect { described_class.perform_now(sale_id) }.not_to raise_error

          expect(Sale::ImportFailure.find_by!(store_name: "shopify", store_order_id: sale_id).message)
            .to start_with("Failed to import product #{product_store_id}: Failed to fetch product: Access denied")
          expect(Sale.count).to eq(0)
        end
      end
    end

    context "when something else breaks and Sidekiq runs the job again" do
      let(:user) { create(:user) }

      before do
        allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
        allow(Sale::Shopify::Importer).to receive(:import).and_raise(RuntimeError, "boom")
      end

      it "tells the requester once" do
        payload = described_class.new(sale_id, requested_by: user).serialize

        expect { 3.times { expect { described_class.execute(payload) }.to raise_error("boom") } }
          .to have_broadcasted_to(user).from_channel(NotificationsChannel)
          .with(kind: "alert", message: "This order could not be pulled from Shopify.", link: {label: "Open broken sales", href: "/broken_sales"})
          .exactly(:once)
      end

      it "keeps raising for a run nobody requested, so Sidekiq retries it" do
        payload = described_class.new(sale_id).serialize

        expect { 3.times { expect { described_class.execute(payload) }.to raise_error("boom") } }
          .not_to have_broadcasted_to(user).from_channel(NotificationsChannel)
        expect(Sale::ImportFailure.count).to eq(0)
      end
    end

    context "when the import fails" do
      let(:import_error) { Sale::Shopify::Importer::Error.new("Failed to process SaleItem") }
      let(:sentry_event) { instance_double(Sentry::ErrorEvent, event_id: "event-1") }

      before do
        allow(Sale::Shopify::Importer).to receive(:import).and_raise(import_error)
        allow(Sentry).to receive(:capture_exception).and_return(sentry_event)
      end

      it "reports the failure, records it with the event id, and discards the job" do
        sale = create(:sale, shopify_store_id: sale_id)

        freeze_time do
          expect { described_class.perform_now(sale_id) }.not_to raise_error

          expect(Sentry).to have_received(:capture_exception).with(import_error)
          expect(Sale::ImportFailure.find_by!(store_name: "shopify", store_order_id: sale_id)).to have_attributes(
            sale:,
            message: "Failed to process SaleItem",
            sentry_event_id: "event-1",
            failure_count: 1,
            last_failed_at: Time.current
          )
        end
      end

      it "reports a recording failure and stays discarded" do
        recording_error = ActiveRecord::StatementInvalid.new("cannot write")
        allow(Sale::ImportFailure).to receive(:record).and_raise(recording_error)

        expect { described_class.perform_now(sale_id) }.not_to raise_error

        expect(Sentry).to have_received(:capture_exception).with(recording_error, extra: {store_name: "shopify", store_order_id: sale_id})
      end

      context "with a customer error" do
        let(:import_error) { Customer::Shopify::Importer::Error.new("Failed to process Customer: Email is invalid") }

        it "reports the failure, records it with the event id, and discards the job" do
          expect { described_class.perform_now(sale_id) }.not_to raise_error

          expect(enqueued_jobs).to be_empty
          expect(Sentry).to have_received(:capture_exception).with(import_error)
          expect(Sale::ImportFailure.find_by!(store_name: "shopify", store_order_id: sale_id)).to have_attributes(
            message: "Failed to process Customer: Email is invalid",
            sentry_event_id: "event-1",
            failure_count: 1
          )
        end
      end

      it "tells the requester the order could not be pulled" do
        user = create(:user)

        expect { described_class.perform_now(sale_id, requested_by: user) }
          .to have_broadcasted_to(user).from_channel(NotificationsChannel)
          .with(kind: "alert", message: "This order could not be pulled from Shopify.", link: {label: "Open broken sales", href: "/broken_sales"})
      end
    end

    it "resolves the order's import failure after a successful pull" do
      Sale::ImportFailure.record(store_name: "shopify", store_order_id: sale_id, message: "boom", sentry_event_id: nil, failed_at: 1.hour.ago)

      job.perform(sale_id)

      expect(Sale::ImportFailure.find_by!(store_name: "shopify", store_order_id: sale_id).resolved_at).to be_present
    end

    context "when sale already exists" do
      before { create(:sale, :synced, shopify_id: sale_id) }

      it "updates existing sale instead of creating duplicate" do
        expect { job.perform(sale_id) }.not_to change(Sale, :count)
      end
    end

    describe "scoped reconciliation handoff" do
      before do
        allow(Seal::ReconcileInstallmentSaleItemsJob).to receive(:perform_later)
      end

      def create_plan(external_origin_order_id:, follow_up_order_id:)
        SalePaymentPlan.reconcile(
          attributes: {
            provider: "seal",
            external_id: "sub-#{external_origin_order_id}",
            external_origin_order_id:,
            kind: "installments",
            status: "active",
            expected_parts: 2,
            synced_at: Time.current
          },
          parts: [
            {sequence: 1, provider_part_id: "origin", external_order_id: external_origin_order_id},
            {sequence: 2, provider_part_id: "attempt-1", external_order_id: follow_up_order_id}
          ]
        )
      end

      it "enqueues scoped reconciliation when the imported sale is a persisted plan's origin" do
        create_plan(external_origin_order_id: "123", follow_up_order_id: "124")

        job.perform(sale_id)

        sale = Sale::Shopify::OrderId.find_sale(sale_id)
        expect(Seal::ReconcileInstallmentSaleItemsJob).to have_received(:perform_later).with(sale_id: sale.id)
      end

      it "enqueues scoped reconciliation when the imported sale is a persisted plan's follow-up part" do
        create_plan(external_origin_order_id: "122", follow_up_order_id: "123")

        job.perform(sale_id)

        sale = Sale::Shopify::OrderId.find_sale(sale_id)
        expect(Seal::ReconcileInstallmentSaleItemsJob).to have_received(:perform_later).with(sale_id: sale.id)
      end

      it "enqueues no reconciliation when the sale is not linked to any persisted plan" do
        job.perform(sale_id)

        expect(Seal::ReconcileInstallmentSaleItemsJob).not_to have_received(:perform_later)
      end
    end
  end
end
