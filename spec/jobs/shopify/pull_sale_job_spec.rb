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

    context "when sale already exists" do
      before { create(:sale, shopify_id: sale_id) }

      it "updates existing sale instead of creating duplicate" do
        expect { job.perform(sale_id) }.not_to change(Sale, :count)
      end
    end

    describe "scoped reconciliation handoff" do
      before do
        allow(Seal::ReconcileInstallmentSaleItemsJob).to receive(:perform_later)
      end

      def create_plan(external_origin_order_id:, follow_up_order_id:)
        SalePaymentPlan.reconcile!(
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
